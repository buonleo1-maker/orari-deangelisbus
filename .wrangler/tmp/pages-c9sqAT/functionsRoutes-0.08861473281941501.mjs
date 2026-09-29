import { onRequestPost as __api_assistente_js_onRequestPost } from "C:\\DEANGELISBUS\\orari-deangelisbus\\functions\\api\\assistente.js"

export const routes = [
    {
      routePath: "/api/assistente",
      mountPath: "/api",
      method: "POST",
      middlewares: [],
      modules: [__api_assistente_js_onRequestPost],
    },
  ]