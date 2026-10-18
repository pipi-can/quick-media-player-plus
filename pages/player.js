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

  applyTheme("light");
  renderVolume();
})();
