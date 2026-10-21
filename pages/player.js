(function () {
  const win = document.getElementById("window");
  const themeMenu = document.getElementById("themeMenu");
  const musicQueue = document.getElementById("musicQueue");
  const musicDownload = document.getElementById("musicDownload");
  const queueChip = document.getElementById("queueChip");
  const dlChip = document.getElementById("dlChip");
  let volume = 70;

  function showPage(name) {
    document.querySelectorAll(".page").forEach(function (page) {
      page.classList.toggle("is-on", page.id === "page-" + name);
    });
    document.querySelectorAll(".nav .pill").forEach(function (pill) {
      pill.classList.toggle("is-on", pill.dataset.page === name);
    });
    closeMusicPanels();
    closePops();
  }

  function closePops() {
    document.querySelectorAll(".menu, .vol, .theme-pop").forEach(function (el) {
      el.classList.remove("is-open");
    });
  }

  function closeMusicPanels() {
    musicQueue.classList.remove("is-open");
    musicDownload.classList.remove("is-open");
    queueChip.classList.remove("is-on");
    dlChip.classList.remove("is-on");
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    themeMenu.querySelectorAll("button").forEach(function (btn) {
      btn.classList.toggle("is-on", btn.dataset.theme === theme);
    });
  }

  function renderVolume() {
    document.querySelectorAll(".vol-fill").forEach(function (fill) {
      fill.style.height = volume + "%";
    });
    document.querySelectorAll(".vol-num").forEach(function (num) {
      num.textContent = volume + "%";
    });
  }

  document.querySelectorAll(".nav .pill").forEach(function (pill) {
    pill.addEventListener("click", function () {
      showPage(pill.dataset.page);
    });
  });

  document.getElementById("settingsBtn").addEventListener("click", function () {
    showPage("settings");
    document.querySelectorAll(".nav .pill").forEach(function (pill) {
      pill.classList.remove("is-on");
    });
  });

  document.getElementById("themeBtn").addEventListener("click", function (event) {
    event.stopPropagation();
    themeMenu.classList.toggle("is-open");
  });

  themeMenu.addEventListener("click", function (event) {
    const btn = event.target.closest("button");
    if (btn) {
      applyTheme(btn.dataset.theme);
    }
  });

  document.querySelectorAll(".mode-btn").forEach(function (btn) {
    btn.addEventListener("click", function (event) {
      event.stopPropagation();
      const menu = btn.parentElement.querySelector(".menu");
      const open = menu.classList.contains("is-open");
      closePops();
      if (!open) {
        menu.classList.add("is-open");
      }
    });
  });

  document.querySelectorAll(".speed-btn").forEach(function (btn) {
    btn.addEventListener("click", function (event) {
      event.stopPropagation();
      const menu = btn.parentElement.querySelector(".menu");
      const open = menu.classList.contains("is-open");
      closePops();
      if (!open) {
        menu.classList.add("is-open");
      }
    });
  });

  document.querySelectorAll("[data-vol]").forEach(function (host) {
    const slider = host.querySelector(".vol-slider");
    const menu = host.querySelector(".vol");
    host.querySelector(".vol-btn").addEventListener("click", function (event) {
      event.stopPropagation();
      const open = menu.classList.contains("is-open");
      closePops();
      if (!open) {
        menu.classList.add("is-open");
      }
    });
    slider.addEventListener("pointerdown", function (event) {
      event.stopPropagation();
      slider.setPointerCapture(event.pointerId);
      const rect = slider.getBoundingClientRect();
      volume = Math.max(0, Math.min(100, Math.round((1 - (event.clientY - rect.top) / rect.height) * 100)));
      renderVolume();
    });
    slider.addEventListener("pointermove", function (event) {
      if (!slider.hasPointerCapture(event.pointerId)) {
        return;
      }
      const rect = slider.getBoundingClientRect();
      volume = Math.max(0, Math.min(100, Math.round((1 - (event.clientY - rect.top) / rect.height) * 100)));
      renderVolume();
    });
  });

  document.querySelectorAll(".menu").forEach(function (menu) {
    menu.addEventListener("click", function (event) {
      const btn = event.target.closest("button");
      if (!btn) {
        return;
      }
      menu.querySelectorAll("button").forEach(function (item) {
        item.classList.toggle("is-on", item === btn);
      });
      const hostBtn = menu.parentElement.querySelector(".mode-btn, .speed-btn");
      if (hostBtn && hostBtn.classList.contains("txt")) {
        hostBtn.textContent = btn.textContent;
      }
    });
  });

  function toggleMusicPanel(panel, chip) {
    const open = !panel.classList.contains("is-open");
    closeMusicPanels();
    closePops();
    panel.classList.toggle("is-open", open);
    chip.classList.toggle("is-on", open);
  }

  queueChip.addEventListener("click", function (event) {
    event.stopPropagation();
    toggleMusicPanel(musicQueue, queueChip);
  });

  dlChip.addEventListener("click", function (event) {
    event.stopPropagation();
    toggleMusicPanel(musicDownload, dlChip);
  });

  document.querySelectorAll(".card[data-open]").forEach(function (card) {
    card.addEventListener("click", function (event) {
      if (event.target.closest(".ico")) {
        return;
      }
      showPage(card.dataset.open);
    });
  });

  document.getElementById("maxBtn").addEventListener("click", function () {
    win.classList.toggle("is-max");
  });

  document.addEventListener("click", function (event) {
    if (!event.target.closest(".pop-host, .theme-pop, #themeBtn")) {
      closePops();
    }
    if (!event.target.closest(".music-drawer, .music-chip, .music-tools")) {
      closeMusicPanels();
    }
  });

  const videoQueue = document.getElementById("videoQueue");
  const fileCard = document.getElementById("fileCard");
  const fileName = document.getElementById("fileName");
  const fileBrief = document.getElementById("fileBrief");
  const fileMore = document.getElementById("fileMore");
  const fileRows = document.getElementById("fileRows");
  const fileFields = [
    ["路径", "path"],
    ["视频编码", "codec"],
    ["解码器", "decoder"],
    ["音频", "audio"]
  ];
  let videoDrag = null;

  function showFile(item) {
    fileName.textContent = item.dataset.file;
    fileBrief.textContent = item.dataset.format + " · " + item.dataset.resolution + " · " + item.dataset.size;
    fileRows.innerHTML = "";
    fileFields.forEach(function (field) {
      const row = document.createElement("div");
      row.className = "file-row";
      const label = document.createElement("span");
      label.textContent = field[0];
      const value = document.createElement("span");
      value.textContent = item.dataset[field[1]];
      row.appendChild(label);
      row.appendChild(value);
      fileRows.appendChild(row);
    });
  }

  fileMore.addEventListener("click", function () {
    const open = fileCard.classList.toggle("is-open");
    fileMore.textContent = open ? "收起" : "详情";
  });

  function selectVideo(item) {
    videoQueue.querySelectorAll(".q-item").forEach(function (el) {
      el.classList.toggle("is-on", el === item);
    });
    showFile(item);
  }

  videoQueue.addEventListener("pointerdown", function (event) {
    const item = event.target.closest(".q-item");
    if (!item) {
      return;
    }
    videoDrag = {
      item: item,
      startY: event.clientY,
      origin: item.offsetTop,
      moved: false,
      pointerId: event.pointerId
    };
    item.setPointerCapture(event.pointerId);
  });

  videoQueue.addEventListener("pointermove", function (event) {
    if (!videoDrag || videoDrag.pointerId !== event.pointerId) {
      return;
    }
    const dy = event.clientY - videoDrag.startY;
    if (Math.abs(dy) > 6) {
      videoDrag.moved = true;
    }
    if (!videoDrag.moved) {
      return;
    }
    videoDrag.item.classList.add("is-dragging");
    let ghost = videoQueue.querySelector(".q-ghost");
    if (!ghost) {
      ghost = document.createElement("div");
      ghost.className = "q-ghost";
      ghost.textContent = videoDrag.item.querySelector(".q-title").textContent;
      videoQueue.appendChild(ghost);
    }
    ghost.style.top = (videoDrag.origin + dy) + "px";
  });

  videoQueue.addEventListener("pointerup", function (event) {
    if (!videoDrag || videoDrag.pointerId !== event.pointerId) {
      return;
    }
    const item = videoDrag.item;
    const moved = videoDrag.moved;
    const ghost = videoQueue.querySelector(".q-ghost");
    const top = ghost ? parseFloat(ghost.style.top) : item.offsetTop;
    if (ghost) {
      ghost.remove();
    }
    item.classList.remove("is-dragging");
    videoDrag = null;
    if (moved) {
      const items = Array.prototype.slice.call(videoQueue.querySelectorAll(".q-item"));
      let dest = Math.round(top / (item.offsetHeight + 4));
      if (dest < 0) {
        dest = 0;
      }
      if (dest >= items.length) {
        dest = items.length - 1;
      }
      const from = items.indexOf(item);
      if (from !== dest) {
        const after = dest > from ? items[dest].nextSibling : items[dest];
        videoQueue.insertBefore(item, after);
      }
    }
    selectVideo(item);
  });

  const videoPlay = document.getElementById("videoPlay");
  const videoScreen = document.querySelector("#page-video .screen");
  videoPlay.addEventListener("click", function () {
    const on = videoScreen.classList.toggle("is-playing");
    videoPlay.querySelector("use").setAttribute("href", on ? "#i-pause" : "#i-play");
  });

  applyTheme("light");
  renderVolume();
  showFile(videoQueue.querySelector(".q-item.is-on"));
})();
