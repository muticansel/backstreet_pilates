import { GoogleAuth } from 'npm:google-auth-library@9'
import { createClient } from 'npm:@supabase/supabase-js@2'

type NotificationEvent = {
  id: string
  event_type: 'cash_request_created' | 'cash_request_confirmed' | 'class_created' | 'registration_approval_requested'
  recipient_user_id: string
  request_id?: string
  class_series_id?: string
  registration_profile_id?: string
  payload: {
    action: 'cash_request' | 'package_confirmed' | 'class_created' | 'registration_pending'
    request_id?: string
    class_series_id?: string
    registration_profile_id?: string
  }
}

const json = { 'Content-Type': 'application/json' }

Deno.serve(async (request) => {
  const webhookSecret = Deno.env.get('NOTIFICATION_WEBHOOK_SECRET')
  if (!webhookSecret || request.headers.get('x-notification-secret') !== webhookSecret) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: json })
  }

  const body = await request.json()
  const event = (body.record ?? body) as NotificationEvent
  if (!event?.id || !event.recipient_user_id || !event.payload?.action) {
    return Response.json({ error: 'Invalid notification event' }, { status: 400, headers: json })
  }
  const validEvent =
    (event.event_type === 'cash_request_created' && event.request_id && event.payload.action === 'cash_request') ||
    (event.event_type === 'cash_request_confirmed' && event.request_id && event.payload.action === 'package_confirmed') ||
    (event.event_type === 'class_created' && event.class_series_id && event.payload.action === 'class_created') ||
    (event.event_type === 'registration_approval_requested' &&
      event.registration_profile_id &&
      event.payload.action === 'registration_pending')
  if (!validEvent) return Response.json({ error: 'Invalid notification event' }, { status: 400, headers: json })

  const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')
  if (!serviceRole || !serviceAccountRaw) {
    return Response.json({ error: 'Push delivery is not configured' }, { status: 503, headers: json })
  }

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, serviceRole)
  const { data: devices, error: deviceError } = await admin
    .from('user_push_devices')
    .select('id, token')
    .eq('user_id', event.recipient_user_id)
    .eq('push_enabled', true)
  if (deviceError) return Response.json({ error: deviceError.message }, { status: 500, headers: json })
  if (!devices?.length) {
    await admin.from('notification_events').update({ delivered_at: new Date().toISOString() }).eq('id', event.id)
    return Response.json({ delivered: 0 }, { headers: json })
  }

  const serviceAccount = JSON.parse(serviceAccountRaw)
  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  })
  const accessToken = await auth.getAccessToken()
  if (!accessToken || !serviceAccount.project_id) {
    return Response.json({ error: 'Firebase credentials are invalid' }, { status: 503, headers: json })
  }

  const copy = event.event_type === 'cash_request_created'
    ? { title: 'Backstreet Pilates', body: 'Yeni bir ödeme talebi var.' }
    : event.event_type === 'cash_request_confirmed'
      ? { title: 'Backstreet Pilates', body: 'Paketin onaylandı.' }
      : event.event_type === 'class_created'
        ? { title: 'Backstreet Pilates', body: 'Yeni bir ders satışa açıldı.' }
        : { title: 'Backstreet Pilates', body: 'E-posta onayını tamamlayan yeni bir kayıt bekliyor.' }
  const results = await Promise.all(devices.map(async (device) => {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: {
            token: device.token,
            notification: copy,
            data: event.payload,
            apns: { payload: { aps: { sound: 'default' } } },
          },
        }),
      },
    )
    const responseBody = response.ok ? undefined : await response.text()
    if (!response.ok) {
      console.error('FCM delivery rejected', {
        notificationEventId: event.id,
        deviceId: device.id,
        status: response.status,
        responseBody,
      })
    }
    return { id: device.id, ok: response.ok, status: response.status }
  }))
  const invalidDeviceIds = results
    .filter((result) => result.status === 404 || result.status === 410)
    .map((result) => result.id)
  if (invalidDeviceIds.length) {
    await admin.from('user_push_devices').delete().in('id', invalidDeviceIds)
  }
  const succeeded = results.some((result) => result.ok)
  await admin.from('notification_events').update(
    succeeded ? { delivered_at: new Date().toISOString() } : { failed_at: new Date().toISOString() },
  ).eq('id', event.id)
  return Response.json({ delivered: results.filter((result) => result.ok).length }, { headers: json })
})
