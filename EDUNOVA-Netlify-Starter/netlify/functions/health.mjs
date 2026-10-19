export default async () => new Response(JSON.stringify({
  app: "EDUNOVA",
  status: "ok",
  supabaseConfigured: Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY)
}), {status:200, headers:{"content-type":"application/json; charset=utf-8","cache-control":"no-store"}});