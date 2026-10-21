#!/usr/bin/env python3
# Qt 6.5 自带的 qmlls 没有「转到定义」。
# 官方新版要 glibc 2.34，这台系统是 2.28，跑不起来。
# 本工程一个控件一个文件、文件名就是控件名，按这个规矩跳。

import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

DOCS = {}
ROOT = os.getcwd()
SKIP = ("id", "property", "function", "import", "signal")


def send(msg):
    body = json.dumps(msg, ensure_ascii=False).encode("utf-8")
    header = ("Content-Length: %d\r\n\r\n" % len(body)).encode("ascii")
    sys.stdout.buffer.write(header + body)
    sys.stdout.buffer.flush()


def read_message():
    header = b""
    while b"\r\n\r\n" not in header:
        chunk = sys.stdin.buffer.read(1)
        if not chunk:
            return None
        header += chunk
    length = 0
    for line in header.split(b"\r\n"):
        if line.lower().startswith(b"content-length:"):
            length = int(line.split(b":", 1)[1].strip())
    body = b""
    while len(body) < length:
        chunk = sys.stdin.buffer.read(length - len(body))
        if not chunk:
            return None
        body += chunk
    return json.loads(body.decode("utf-8"))


def uri_path(uri):
    return unquote(urlparse(uri).path)


def path_uri(path):
    return Path(path).resolve().as_uri()


def source_root():
    nested = os.path.join(ROOT, "quick-media-player")
    if os.path.isdir(os.path.join(nested, "qml")):
        return nested
    return ROOT


def read_text(path):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return handle.read()
    except OSError:
        return ""


def walk_sources(suffixes):
    for folder, _, files in os.walk(source_root()):
        if folder.split(os.sep).count("build"):
            continue
        for name in files:
            if name.endswith(suffixes):
                yield os.path.join(folder, name)


def word_at(text, line, col):
    lines = text.splitlines()
    if line < 0 or line >= len(lines):
        return "", 0
    row = lines[line]
    if col > len(row):
        col = len(row)
    left = col
    while left > 0 and (row[left - 1].isalnum() or row[left - 1] == "_"):
        left -= 1
    right = col
    while right < len(row) and (row[right].isalnum() or row[right] == "_"):
        right += 1
    return row[left:right], left


def owner_before(text, line, column):
    lines = text.splitlines()
    if line < 0 or line >= len(lines):
        return ""
    match = re.search(r"([A-Za-z_]\w*)\s*\.\s*$", lines[line][:column])
    if not match:
        return ""
    return match.group(1)


def collect(text, patterns, name):
    found = []
    for index, line in enumerate(text.splitlines()):
        for pattern in patterns:
            match = re.search(pattern, line)
            if not match:
                continue
            column = line.find(name, match.start())
            if column < 0:
                column = match.start()
            found.append((index, column, column + len(name)))
            break
    return found


def decl_patterns(name):
    token = re.escape(name)
    return [
        r"\bfunction\s+" + token + r"\s*\(",
        r"\bsignal\s+" + token + r"\b",
        r"\bid\s*:\s*" + token + r"\b",
        r"\bproperty\s+alias\s+" + token + r"\b",
        r"\bproperty\s+[\w.<>:]+\s+" + token + r"\b",
        r"\b(?:class|struct|enum)\s+" + token + r"\b",
    ]


def member_patterns(name):
    token = re.escape(name)
    return decl_patterns(name) + [
        r"\b[\w:]+\s+" + token + r"\s*\(",
        r"\b" + token + r"\s*=",
    ]


def to_locations(path, found):
    uri = path_uri(path)
    locations = []
    for line, start, end in found[:8]:
        locations.append({
            "uri": uri,
            "range": {
                "start": {"line": line, "character": start},
                "end": {"line": line, "character": end},
            },
        })
    return locations


def qml_file(type_name):
    for path in walk_sources(".qml"):
        stem = os.path.splitext(os.path.basename(path))[0]
        if stem == type_name:
            return path
    return ""


def component_of_id(text, id_name):
    lines = text.splitlines()
    pattern = r"\bid\s*:\s*" + re.escape(id_name) + r"\b"
    id_line = -1
    for index, line in enumerate(lines):
        if re.search(pattern, line):
            id_line = index
            break
    if id_line < 0:
        return ""
    for index in range(id_line, -1, -1):
        match = re.search(r"\b([A-Z]\w*)\s*\{", lines[index])
        if match:
            return match.group(1)
    return ""


def type_of(text, name):
    component = component_of_id(text, name)
    if component:
        return component
    match = re.search(
        r"\bproperty\s+([A-Z]\w*)\s+" + re.escape(name) + r"\b", text)
    if match:
        return match.group(1)
    if name[:1].isupper():
        return name
    return ""


def cpp_files_matching(pattern):
    found = []
    for path in walk_sources((".h", ".hpp", ".cpp")):
        if re.search(pattern, read_text(path)):
            found.append(path)
    return found


def class_files(type_name):
    pattern = r"\b(?:class|struct|enum)\s+" + re.escape(type_name) + r"\b"
    return cpp_files_matching(pattern)


def register_spot(type_name):
    needle = '"%s"' % type_name
    for path in walk_sources((".h", ".hpp", ".cpp")):
        lines = read_text(path).splitlines()
        blob = "\n".join(lines)
        if "qmlRegister" not in blob:
            continue
        for index, line in enumerate(lines):
            column = line.find(needle)
            if column >= 0:
                return path, index, column + 1
    return "", -1, 0


def register_class(type_name):
    path, index, _ = register_spot(type_name)
    if not path:
        return ""
    lines = read_text(path).splitlines()
    for line in lines[max(0, index - 6):index + 1]:
        match = re.search(r"\b([A-Za-z_]\w*)::staticMetaObject", line)
        if match:
            return match.group(1)
    return ""


def file_root(path):
    for index, line in enumerate(read_text(path).splitlines()):
        match = re.search(r"\b([A-Z]\w*)\s*\{", line)
        if match:
            return to_locations(path, [(index, match.start(1), match.end(1))])
    return to_locations(path, [(0, 0, 0)])


def type_locations(type_name):
    qml_path = qml_file(type_name)
    if qml_path:
        return file_root(qml_path)
    locations = []
    for path in class_files(type_name):
        locations.extend(to_locations(
            path, collect(read_text(path), decl_patterns(type_name), type_name)))
    if locations:
        return locations
    path, line, column = register_spot(type_name)
    if not path:
        return []
    return to_locations(path, [(line, column, column + len(type_name))])


def member_locations(type_name, member):
    files = []
    qml_path = qml_file(type_name)
    if qml_path:
        files.append(qml_path)
    else:
        files.extend(class_files(type_name))
        owner = register_class(type_name)
        if owner:
            files.extend(class_files(owner))
    locations = []
    patterns = member_patterns(member)
    for path in files:
        locations.extend(to_locations(
            path, collect(read_text(path), patterns, member)))
    if locations:
        return locations
    return type_locations(type_name)


def define_at(path, text, line, column):
    name, start = word_at(text, line, column)
    if not name or name in SKIP:
        return None
    owner = owner_before(text, line, start)
    if owner:
        type_name = type_of(text, owner)
        if not type_name:
            return None
        return member_locations(type_name, name) or None
    local = to_locations(path, collect(text, decl_patterns(name), name))
    if local:
        return local
    found = type_locations(name)
    if found:
        return found
    return None


def on_definition(params):
    uri = params.get("textDocument", {}).get("uri", "")
    position = params.get("position", {})
    text = DOCS.get(uri)
    path = uri_path(uri)
    if text is None:
        text = read_text(path)
    return define_at(path, text, position.get("line", 0), position.get("character", 0))


def handle(msg):
    global ROOT
    method = msg.get("method", "")
    msg_id = msg.get("id")
    params = msg.get("params") or {}
    if method == "initialize":
        root_uri = params.get("rootUri") or ""
        if root_uri:
            ROOT = uri_path(root_uri)
        send({
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {
                "capabilities": {
                    "textDocumentSync": 1,
                    "definitionProvider": True,
                }
            },
        })
        return True
    if method == "shutdown":
        send({"jsonrpc": "2.0", "id": msg_id, "result": None})
        return True
    if method == "exit":
        return False
    if method == "textDocument/didOpen":
        doc = params.get("textDocument", {})
        DOCS[doc.get("uri", "")] = doc.get("text", "")
        return True
    if method == "textDocument/didChange":
        changes = params.get("contentChanges") or []
        if changes:
            uri = params.get("textDocument", {}).get("uri", "")
            DOCS[uri] = changes[-1].get("text", "")
        return True
    if method == "textDocument/didClose":
        DOCS.pop(params.get("textDocument", {}).get("uri", ""), None)
        return True
    if method == "textDocument/definition" and msg_id is not None:
        send({"jsonrpc": "2.0", "id": msg_id, "result": on_definition(params)})
        return True
    if msg_id is not None:
        send({
            "jsonrpc": "2.0",
            "id": msg_id,
            "error": {"code": -32601, "message": "unsupported"},
        })
    return True


def main():
    if "--help" in sys.argv or "-h" in sys.argv:
        sys.stdout.write("qml goto server\n")
        return 0
    while True:
        msg = read_message()
        if msg is None:
            return 0
        if not handle(msg):
            return 0


if __name__ == "__main__":
    sys.exit(main())
