import { Moon, Sun } from "lucide-react";
import { useTheme } from "./themeContext.js";
import { useLanguage } from "../i18n/useLanguage.js";
import "./ThemeToggle.css";

export default function ThemeToggle({ compact = false }) {
  const { theme, toggleTheme } = useTheme();
  const { t } = useLanguage();
  const nextTheme = theme === "dark" ? "light" : "dark";
  const Icon = theme === "dark" ? Sun : Moon;
  const nextThemeLabel = t(`Switch to ${nextTheme} mode`);

  return <button className={`theme-toggle${compact ? " theme-toggle-compact" : ""}`} type="button" onClick={toggleTheme} aria-label={nextThemeLabel} aria-pressed={theme === "light"} title={nextThemeLabel}>
    <Icon size={15} />
    {!compact && <span>{t(theme === "dark" ? "Dark" : "Light")}</span>}
  </button>;
}
