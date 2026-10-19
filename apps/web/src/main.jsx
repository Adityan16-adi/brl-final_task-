import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import App from './App.jsx';

// Apply the saved accessibility preference before the first paint.
try {
  const preferences = JSON.parse(window.localStorage.getItem('unified-learn-preview-preferences') || '{}');
  document.documentElement.dataset.reduceMotion = preferences.motion ? 'true' : 'false';
} catch {
  document.documentElement.dataset.reduceMotion = 'false';
}

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
