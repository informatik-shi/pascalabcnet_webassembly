const themeStorageKey = "pascalabc-web-theme";
const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");

function savedTheme() {
  try {
    const value = localStorage.getItem(themeStorageKey);
    return value === "light" || value === "dark" ? value : null;
  } catch {
    return null;
  }
}

function applyTheme(theme, persist = false) {
  const isDark = theme === "dark";
  document.documentElement.dataset.theme = theme;
  document.documentElement.style.colorScheme = theme;

  if (persist) {
    try {
      localStorage.setItem(themeStorageKey, theme);
    } catch {
      // The theme still works when storage is unavailable.
    }
  }

  const toggle = document.getElementById("theme-toggle");
  const label = document.getElementById("theme-label");
  const icon = toggle?.querySelector(".theme-toggle-icon");
  if (!toggle || !label || !icon) return;

  toggle.setAttribute("aria-pressed", String(isDark));
  toggle.setAttribute("aria-label", isDark ? "Включить светлую тему" : "Включить тёмную тему");
  toggle.title = isDark ? "Включить светлую тему" : "Включить тёмную тему";
  label.textContent = isDark ? "Тёмная тема" : "Светлая тема";
  icon.textContent = isDark ? "☾" : "☀";
}

applyTheme(savedTheme() ?? (systemTheme.matches ? "dark" : "light"));

window.addEventListener("DOMContentLoaded", () => {
  applyTheme(document.documentElement.dataset.theme);

  document.getElementById("theme-toggle")?.addEventListener("click", () => {
    const nextTheme = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    applyTheme(nextTheme, true);
  });

  systemTheme.addEventListener("change", event => {
    if (!savedTheme()) applyTheme(event.matches ? "dark" : "light");
  });
});
