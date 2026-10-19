import { useLanguage } from "./useLanguage.js";
import "./LanguageSelector.css";

export default function LanguageSelector() {
  const { language, setLanguage, t } = useLanguage();
  return <label className="language-selector">
    <span className="language-selector-label">{t("Choose language")}</span>
    <select value={language} onChange={(event) => setLanguage(event.target.value)} aria-label={t("Choose language")}>
      <option value="en">English</option>
      <option value="hi">हिन्दी</option>
    </select>
  </label>;
}
