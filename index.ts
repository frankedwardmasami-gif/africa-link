import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed",{status:405});
  const signature=req.headers.get("x-provider-signature");
  if (!signature) return new Response("Missing signature",{status:400});
  const raw=await req.text();
  // Production: verify the provider signature cryptographically before updating orders/payments.
  console.log("payment webhook received", raw.length);
  return new Response("ok");
});
