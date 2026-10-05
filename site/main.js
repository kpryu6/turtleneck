// Demo: cycle the alert through the three levels, like the real app escalates.
(function () {
  const banner = document.getElementById("banner");
  const msg = document.getElementById("banner-msg");
  const tray = document.getElementById("tray");
  const steps = document.querySelectorAll(".levels li");
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const lines = {
    1: ["Hey buddy, I came out just for you 🐢", "Psst... your posture is slipping", "Shoulders back, just a little~"],
    2: ["Your spine called. It wants a divorce.", "Again? I JUST told you 💢", "I'm not mad, I'm just... disappointed 💢"],
    3: ["Your posture is a CRIME and I'm the police 🚨", "SIT. UP. RIGHT. NOW. 🔥", "I will NOT leave until you sit properly."],
  };
  let level = 1, round = 0;

  function show(l) {
    const pick = lines[l][round % lines[l].length];
    banner.dataset.level = l;
    tray.dataset.level = l;
    msg.textContent = pick;
    steps.forEach((s) => s.classList.toggle("on", Number(s.dataset.level) === l));
  }

  function next() {
    if (reduced) { show(level); level = level % 3 + 1; return; }
    banner.classList.add("out");
    setTimeout(() => {
      level = level % 3 + 1;
      if (level === 1) round++;
      show(level);
      banner.classList.remove("out");
    }, 500);
  }

  show(level);
  setInterval(next, 3200);
})();

// Install tabs
(function () {
  const tabs = document.querySelectorAll('[role="tab"]');
  function select(name) {
    tabs.forEach((t) => {
      const on = t.dataset.tab === name;
      t.setAttribute("aria-selected", on);
      document.getElementById(t.getAttribute("aria-controls")).hidden = !on;
    });
  }
  tabs.forEach((t) => t.addEventListener("click", () => select(t.dataset.tab)));
  document.querySelectorAll("a[data-tab]").forEach((a) =>
    a.addEventListener("click", () => select(a.dataset.tab))
  );
  // Default to the visitor's platform
  if (/Windows/i.test(navigator.userAgent)) select("windows");
})();

// Download menus: macOS / Windows, with the visitor's platform first
(function () {
  const ua = navigator.userAgent;
  const mobile = /iPhone|iPad|Android/i.test(ua);
  const os = mobile ? null : /Windows/i.test(ua) ? "windows" : /Macintosh|Mac OS X/i.test(ua) ? "mac" : null;
  const menus = [...document.querySelectorAll("[data-dl]")];

  function close(dl, focusToggle) {
    const btn = dl.querySelector(".dl-toggle");
    btn.setAttribute("aria-expanded", "false");
    dl.querySelector(".dl-menu").hidden = true;
    if (focusToggle) btn.focus();
  }

  menus.forEach((dl) => {
    const btn = dl.querySelector(".dl-toggle");
    const menu = dl.querySelector(".dl-menu");
    const items = () => [...menu.querySelectorAll(".dl-item")];

    if (os) {
      const mine = menu.querySelector(`[data-os="${os}"]`);
      mine.querySelector(".dl-badge").hidden = false;
      menu.prepend(mine);
    }

    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      const open = btn.getAttribute("aria-expanded") === "true";
      menus.forEach((m) => close(m));
      if (!open) {
        btn.setAttribute("aria-expanded", "true");
        menu.hidden = false;
        if (e.detail === 0) items()[0].focus(); // opened with the keyboard
      }
    });
    menu.addEventListener("keydown", (e) => {
      const list = items();
      const i = list.indexOf(document.activeElement);
      if (e.key === "ArrowDown") { e.preventDefault(); list[(i + 1) % list.length].focus(); }
      if (e.key === "ArrowUp") { e.preventDefault(); list[(i - 1 + list.length) % list.length].focus(); }
      if (e.key === "Escape") close(dl, true);
    });
    menu.addEventListener("click", () => close(dl));
  });

  document.addEventListener("click", (e) => {
    menus.forEach((dl) => { if (!dl.contains(e.target)) close(dl); });
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") menus.forEach((dl) => close(dl));
  });
})();

// Copy buttons
const KO = document.documentElement.lang.startsWith("ko");
const T = KO
  ? { copy: "복사", copied: "복사됨", manual: "⌘C로 복사" }
  : { copy: "Copy", copied: "Copied", manual: "Press ⌘C" };
document.querySelectorAll(".copy").forEach((btn) => {
  btn.addEventListener("click", async () => {
    const text = btn.previousElementSibling.textContent;
    try {
      await navigator.clipboard.writeText(text);
      btn.textContent = T.copied;
    } catch {
      btn.textContent = T.manual;
      const range = document.createRange();
      range.selectNodeContents(btn.previousElementSibling);
      const sel = getSelection(); sel.removeAllRanges(); sel.addRange(range);
    }
    setTimeout(() => (btn.textContent = T.copy), 1600);
  });
});

// GitHub stars (best effort; hidden if the API is unavailable or rate-limited)
fetch("https://api.github.com/repos/kpryu6/turtleneck")
  .then((r) => (r.ok ? r.json() : null))
  .then((repo) => {
    if (!repo || !(repo.stargazers_count > 0)) return;
    const el = document.getElementById("stars");
    el.textContent = repo.stargazers_count >= 1000
      ? (repo.stargazers_count / 1000).toFixed(1) + "k"
      : String(repo.stargazers_count);
    el.hidden = false;
  })
  .catch(() => {});
