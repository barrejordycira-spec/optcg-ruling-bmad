import * as Sentry from '@sentry/nextjs'

Sentry.init({
  // Client-side needs a NEXT_PUBLIC_ var — plain SENTRY_DSN is not exposed to the browser.
  // Must be present at BUILD time (see Dockerfile ARG) to be inlined into the client bundle.
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1,
  debug: false,
})

export const onRouterTransitionStart = Sentry.captureRouterTransitionStart
