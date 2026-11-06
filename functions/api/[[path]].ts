interface Env {
  BACKEND_API_ORIGIN?: string;
}

interface PagesContext {
  request: Request;
  env: Env;
}

const DEFAULT_BACKEND_ORIGIN =
  'https://onta-my-money-api.gerald.prod.page';
const COOKIE_NAME = '__Secure-onta_refresh';
const REFRESH_PATH = '/api/auth/refresh';
const CLEAR_COOKIE =
  `${COOKIE_NAME}=; Path=/api/auth; Max-Age=0; Secure; HttpOnly; SameSite=Strict`;

function readCookie(header: string | null, name: string): string | null {
  for (const part of (header ?? '').split(';')) {
    const separator = part.indexOf('=');
    if (separator < 0 || part.slice(0, separator).trim() !== name) continue;
    try {
      return decodeURIComponent(part.slice(separator + 1).trim());
    } catch {
      return null;
    }
  }
  return null;
}

function responseWithCookie(response: Response, cookie?: string): Response {
  const headers = new Headers(response.headers);
  headers.set('cache-control', 'no-store');
  if (cookie != null) {
    headers.append('set-cookie', cookie.length === 0 ? CLEAR_COOKIE :
      `${COOKIE_NAME}=${encodeURIComponent(cookie)}; Path=/api/auth; Max-Age=2592000; Secure; HttpOnly; SameSite=Strict`);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export async function onRequest({ request, env }: PagesContext): Promise<Response> {
  const incoming = new URL(request.url);
  if (!incoming.pathname.startsWith('/api/')) {
    return new Response('Not found', { status: 404 });
  }

  if (!['GET', 'HEAD', 'OPTIONS'].includes(request.method) &&
      request.headers.get('origin') !== incoming.origin) {
    return new Response('Invalid request origin', {
      status: 403,
      headers: { 'cache-control': 'no-store' },
    });
  }

  const backendOrigin = env.BACKEND_API_ORIGIN ?? DEFAULT_BACKEND_ORIGIN;
  let target: URL;
  try {
    target = new URL(`${incoming.pathname}${incoming.search}`, backendOrigin);
    if (target.origin !== new URL(backendOrigin).origin) {
      return new Response('Invalid backend route', { status: 400 });
    }
  } catch {
    return new Response('Backend unavailable', { status: 502 });
  }

  const headers = new Headers(request.headers);
  headers.delete('cookie');
  headers.delete('host');
  headers.delete('content-length');

  let body: BodyInit | undefined;
  if (!['GET', 'HEAD'].includes(request.method)) {
    if (incoming.pathname === REFRESH_PATH) {
      let requestedRefresh: string | undefined;
      try {
        const parsed = await request.clone().json() as { refresh_token?: unknown };
        if (typeof parsed.refresh_token === 'string') {
          requestedRefresh = parsed.refresh_token;
        }
      } catch {
        // An empty body is valid when the refresh cookie is present.
      }
      const refresh = readCookie(request.headers.get('cookie'), COOKIE_NAME) ??
        requestedRefresh;
      if (refresh == null) {
        return responseWithCookie(new Response(
          JSON.stringify({ message: 'Session expired' }),
          { status: 401, headers: { 'content-type': 'application/json' } }),
          '');
      }
      headers.set('content-type', 'application/json');
      body = JSON.stringify({ refresh_token: refresh });
    } else {
      body = await request.arrayBuffer();
    }
  }

  let upstream: Response;
  try {
    upstream = await fetch(target, {
      method: request.method,
      headers,
      body,
      redirect: 'manual',
    });
  } catch {
    return new Response('Backend unavailable', {
      status: 502,
      headers: { 'cache-control': 'no-store' },
    });
  }

  const isLogin = incoming.pathname === '/api/auth/login';
  const isRefresh = incoming.pathname === REFRESH_PATH;
  const clearsSession = incoming.pathname === '/api/auth/logout' ||
      incoming.pathname === '/api/auth/logout-all';
  if (!isLogin && !isRefresh && !clearsSession) {
    return responseWithCookie(upstream);
  }

  if (clearsSession) return responseWithCookie(upstream, '');
  if (isRefresh && upstream.status === 401) {
    return responseWithCookie(upstream, '');
  }
  if (upstream.status < 200 || upstream.status >= 300) {
    return responseWithCookie(upstream);
  }

  let data: Record<string, unknown>;
  try {
    data = await upstream.clone().json() as Record<string, unknown>;
  } catch {
    return responseWithCookie(upstream);
  }

  const refreshToken = data.refresh_token;
  const headersOut = new Headers(upstream.headers);
  headersOut.set('cache-control', 'no-store');
  headersOut.delete('content-length');
  delete data.refresh_token;
  const response = new Response(JSON.stringify(data), {
    status: upstream.status,
    headers: headersOut,
  });
  return responseWithCookie(response,
    typeof refreshToken === 'string' ? refreshToken : undefined);
}
