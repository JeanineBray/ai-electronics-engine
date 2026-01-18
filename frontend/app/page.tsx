"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabaseClient";
import { apiGet } from "@/lib/api";

export default function Home() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<string>("");
  const [userId, setUserId] = useState<string>("");
  const [accessTokenPreview, setAccessTokenPreview] = useState<string>("");

  // Keep UI in sync with auth state
  useEffect(() => {
    async function loadSession() {
      const { data } = await supabase.auth.getSession();
      const session = data.session;
      setUserId(session?.user?.id ?? "");
      setAccessTokenPreview(session?.access_token ? session.access_token.slice(0, 12) + "..." : "");
    }

    loadSession();

    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => {
      setUserId(session?.user?.id ?? "");
      setAccessTokenPreview(session?.access_token ? session.access_token.slice(0, 12) + "..." : "");
    });

    return () => sub.subscription.unsubscribe();
  }, []);

  async function signInWithEmail() {
    setStatus("Sending magic link...");
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: "http://localhost:3000"
      }
    });
    setStatus(error ? `Error: ${error.message}` : "Check your email for the sign-in link.");
  }

  async function signOut() {
    await supabase.auth.signOut();
    setStatus("Signed out.");
  }

  async function testBackendMe() {
    try {
      const res = await apiGet("/me");
      setStatus(`Backend verified user: ${res.user_id}`);
    } catch (e: any) {
      setStatus(`Backend error: ${e.message}`);
    }
  }

  return (
    <div style={{ padding: 24, maxWidth: 560 }}>
      <h1>AI Electronics Learning Engine</h1>

      {!userId ? (
        <>
          <p>Sign in with a magic link (no password).</p>

          <input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@email.com"
            style={{ width: "100%", padding: 10, marginTop: 8 }}
          />

          <button onClick={signInWithEmail} style={{ padding: 10, width: "100%", marginTop: 10 }}>
            Send magic link
          </button>
        </>
      ) : (
        <>
          <p><b>Signed in</b></p>
          <p>User ID: <code>{userId}</code></p>
          <p>Access token: <code>{accessTokenPreview}</code></p>

          <button onClick={testBackendMe} style={{ padding: 10, width: "100%", marginTop: 10 }}>
            Test backend /me
          </button>

          <button onClick={signOut} style={{ padding: 10, width: "100%", marginTop: 10 }}>
            Sign out
          </button>
        </>
      )}

      <p style={{ marginTop: 16 }}>{status}</p>
    </div>
  );
}
