# Video library foundation

Status: prepared for review. The migration has not been run on Supabase.

## User experience

A paid video series contains ordered videos. A successful purchase grants the
user access for the duration defined by that series, initially 365 days. The
user can resume a video from their last saved position during that period.

The app will later show a library page, a series-detail page and a player page.
This document covers only the data and access foundation, not those screens.

## Tables

| Table | Purpose |
|---|---|
| `video_series` | Public catalogue information, cover image, publication state and access duration. |
| `series_videos` | Ordered video titles, thumbnails and duration. |
| `private.video_playback_assets` | Streaming-provider asset IDs, never readable by the app client. |
| `video_series_access` | A user's paid or manual access period; expiry and revocation are explicit. |
| `video_progress` | The user's saved watched position and completion time. |

## Access rules

- Signed-in members can browse published series and their published video lists.
- They can view only their own access history and progress.
- A member can save progress only for a published video in a currently active,
  unrevoked access period.
- The Flutter client cannot create access grants, edit expiry dates or see
  streaming-provider asset IDs.
- Admin catalogue editing is allowed through the existing server-verified admin
  role. Granting access remains a server operation, even for admins.

## Streaming and purchase flow

1. Admin uploads a source video to a streaming provider such as Mux or
   Cloudflare Stream and records the provider asset ID in the private table.
2. The user purchases the series through App Store / Play Store billing.
3. A verified RevenueCat webhook or server function records an access grant with
   `expires_at = starts_at + 365 days`.
4. Before playback, a Supabase Edge Function checks the access record and
   creates a short-lived provider playback URL.
5. Flutter plays that URL with `video_player`; it never receives a permanent
   storage or provider URL.

The payment webhook must be idempotent: its provider transaction identifier is
stored as the unique `purchase_reference`, so the same event cannot grant access
twice.

## Future production architecture

This is the agreed direction for the future implementation. It is a decision
record, not an installed integration.

| Layer | Planned responsibility |
|---|---|
| Flutter | Catalogue, library, series-detail and player UI; asks the backend whether playback is allowed. |
| `video_player` | Base iOS and Android playback component for a short-lived streaming URL. |
| RevenueCat / `purchases_flutter` | Presents the native store purchase flow, restores purchases and provides a common entitlement view across iOS and Android. |
| App Store / Google Play | Process payment for digital video access. Product IDs are configured in the stores and mapped in RevenueCat. |
| RevenueCat webhook | Sends verified purchase, renewal, cancellation and refund events to a Supabase Edge Function. |
| Supabase Edge Functions | Verifies webhook events, grants/revokes access, creates time-limited playback URLs and records audit-safe payment references. |
| Supabase PostgreSQL | Stores the catalogue, access periods and watch progress. It never stores card data or a permanent playback URL. |
| Mux or Cloudflare Stream | Hosts/transcodes video and supplies protected streaming playback. One provider will be selected before implementation. |

### Purchase and entitlement rules

- Each series will have a stable store product ID and a matching RevenueCat
  entitlement, for example `series_foundations_access`.
- A verified store event, never a Flutter client request, creates or changes a
  `video_series_access` record.
- The same verified transaction must be safe to receive more than once. Its
  transaction/event ID becomes the unique purchase reference.
- Restore purchases must recreate or confirm access on a new device without
  asking the user to pay again.
- Refund, revocation and expiration events remove playback permission but leave
  a read-only purchase history for support and reporting.
- A 365-day, one-time access product needs a store-product decision before
  launch: after expiry, can the same user buy it again, or is renewal a distinct
  product? We will decide this before creating App Store and Play products.

### Security boundaries

- RevenueCat public SDK keys may be delivered to the mobile app through runtime
  configuration; RevenueCat secret keys, store server credentials, Supabase
  service-role key and streaming-provider API keys are Edge Function secrets.
- Flutter never trusts a local `isPurchased` flag and never writes access or
  expiry records directly.
- The playback endpoint receives the signed-in user and video ID, checks active
  access on the server, then returns a short-lived URL. It must not return a
  provider asset ID or a reusable permanent URL.
- Physical studio-package payments and digital-video payments remain separate
  flows. The video flow uses native store billing because it unlocks digital
  content inside the mobile app.

### Implementation order

1. Review and apply the video-library migration and its SQL access test.
2. Select one streaming provider and prepare a non-production video asset.
3. Create store products and RevenueCat entitlements, then implement the
   verified webhook and access-grant function.
4. Add `purchases_flutter` and `video_player` when the catalogue/player pages
   are being built.
5. Build the library, series-detail and player pages one at a time, with review
   notes and device testing for each.

## Review points

- Is a single 365-day access period the intended first product, or should the
  admin be able to choose a different duration for a specific sale?
- Should users retain a read-only record of an expired purchase in the app?
  The current design does.
- The first player page will not support downloads or offline playback. Those
  need a separate content-protection decision.
- Which store-product type will support a repeat purchase after a 365-day
  access period is still a product decision; it must be resolved before store
  setup.

## Files to review

- `supabase/migrations/20260927000200_video_library.sql`
- `supabase/tests/video_library_access_checks.sql`
- This document

Do not run the migration until it has been reviewed. The existing catalogue,
physical-class memberships and dashboard preview remain unchanged.
