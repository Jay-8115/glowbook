import React, { createContext, useContext, useState, useEffect, useRef } from "react";
import { setBaseUrl, setAuthTokenGetter } from "@workspace/api-client-react";

interface AuthContextType {
  token: string | null;
  login: (token: string) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

const TIMEOUT_DURATION = 15 * 60 * 1000; // 15 minutes in milliseconds

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(() => sessionStorage.getItem("admin_token"));
  const lastActivityRef = useRef<number>(Date.now());

  // Function to reset the activity timer
  const resetTimer = () => {
    lastActivityRef.current = Date.now();
    sessionStorage.setItem("admin_last_activity", lastActivityRef.current.toString());
  };

  const logout = () => {
    sessionStorage.removeItem("admin_token");
    sessionStorage.removeItem("admin_last_activity");
    setToken(null);
  };

  useEffect(() => {
    setBaseUrl("http://localhost:8000");
    setAuthTokenGetter(() => sessionStorage.getItem("admin_token"));

    // Check on initial load if session already expired
    const savedLastActivity = sessionStorage.getItem("admin_last_activity");
    const tokenExists = sessionStorage.getItem("admin_token");
    if (tokenExists && savedLastActivity) {
      const elapsed = Date.now() - parseInt(savedLastActivity, 10);
      if (elapsed >= TIMEOUT_DURATION) {
        logout();
        return;
      }
    }
    
    // Initialize activity timer
    resetTimer();

    // Listen to user activity events to reset inactivity timer
    const events = ["mousedown", "mousemove", "keydown", "scroll", "touchstart"];
    const handleActivity = () => resetTimer();

    events.forEach((event) => {
      window.addEventListener(event, handleActivity);
    });

    // Check inactivity status every 5 seconds
    const interval = setInterval(() => {
      const savedActivity = sessionStorage.getItem("admin_last_activity");
      const currentToken = sessionStorage.getItem("admin_token");
      if (currentToken && savedActivity) {
        const elapsed = Date.now() - parseInt(savedActivity, 10);
        if (elapsed >= TIMEOUT_DURATION) {
          logout();
        }
      }
    }, 5000);

    return () => {
      events.forEach((event) => {
        window.removeEventListener(event, handleActivity);
      });
      clearInterval(interval);
    };
  }, [token]);

  const login = (newToken: string) => {
    sessionStorage.setItem("admin_token", newToken);
    resetTimer();
    setToken(newToken);
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
