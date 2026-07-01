import * as Sentry from '@sentry/nextjs'

export async function register(): Promise<void> {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    // 10% of transactions traced in prod to control Sentry quota/cost; full in dev.
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1,
    debug: false,
  })
}
