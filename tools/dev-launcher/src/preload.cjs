const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("deepFactoryLauncher", {
  getState: () => ipcRenderer.invoke("launcher:get-state"),
  chooseRepository: () => ipcRenderer.invoke("launcher:choose-repository"),
  chooseGodot: () => ipcRenderer.invoke("launcher:choose-godot"),
  startDevelopment: () => ipcRenderer.invoke("launcher:start-development"),
  sync: () => ipcRenderer.invoke("launcher:sync"),
  openEditor: () => ipcRenderer.invoke("launcher:open-editor"),
  runGame: () => ipcRenderer.invoke("launcher:run-game"),
  openFolder: () => ipcRenderer.invoke("launcher:open-folder"),
  openGitHub: () => ipcRenderer.invoke("launcher:open-github")
});
