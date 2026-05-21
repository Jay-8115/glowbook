import React, { createContext, useContext, useState, useEffect } from "react";
import { setBaseUrl, setAuthTokenGetter } from "@workspace/api-client-react";

interface AuthContextType {
  token: string | null;
  login: (token: string) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem("admin_token"));

  useEffect(() => {
    setBaseUrl("");
    setAuthTokenGetter(() => localStorage.getItem("admin_token"));
  }, []);

  const login = (newToken: string) => {
    localStorage.setItem("admin_token", newToken);
    setToken(newToken);
  };

  const logout = () => {
    localStorage.removeItem("admin_token");
    setToken(null);
  };

  return (
    <AuthContext.Provider value={{ token, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
