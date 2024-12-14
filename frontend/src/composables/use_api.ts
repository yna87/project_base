import Api from "@/api/api";

export function useApi() {
    const api = new Api();

    return api;
}

