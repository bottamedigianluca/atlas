import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import "./stile.css";

const radice = document.getElementById("radice");
if (!radice) throw new Error("manca #radice");
createRoot(radice).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
