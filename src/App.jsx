import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthPage, LogoutPage, PortalPage, Workspace } from "./app/AppViews.jsx";
import LandingPage from "./app/LandingPage.jsx";
import { ThemeProvider } from "./app/ThemeContext.jsx";
import { LanguageProvider } from "./i18n/LanguageProvider.jsx";

export default function App() {
  return <ThemeProvider>
    <LanguageProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/login" element={<PortalPage mode="login" />} />
          <Route path="/register" element={<PortalPage mode="register" />} />
          <Route path="/student/login" element={<AuthPage mode="login" />} />
          <Route path="/student/register" element={<AuthPage mode="register" />} />
          <Route path="/teacher/login" element={<AuthPage mode="login" />} />
          <Route path="/teacher/register" element={<AuthPage mode="register" />} />
          <Route path="/forgot-password" element={<AuthPage mode="forgot" />} />
          <Route path="/logout" element={<LogoutPage />} />
          <Route path="/app/*" element={<Workspace />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </LanguageProvider>
  </ThemeProvider>;
}
