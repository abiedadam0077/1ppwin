# AdMob and `app-ads.txt` — verification notes

**Checked:** 2026-10-12. This is an implementation checklist, not confirmation of approval, app verification, or earnings.

## What is in this repository

- Release Android manifest: the supplied AdMob App ID `ca-app-pub-8333402469736519~5380632760`.
- Release ad units: Banner `ca-app-pub-8333402469736519/8587134624`; Interstitial `ca-app-pub-8333402469736519/5268952122`.
- Debug/profile builds: Google's official sample/test App ID and test Banner/Interstitial units.
- `docs/app-ads.txt.template`: a seller line derived from the supplied publisher ID. It is a **template only**; it is not hosted or verified.

The IDs were copied from the app owner's message. This repository cannot confirm that they exist in the correct AdMob account or that the app is approved to serve production ads.

## Direct-APK distribution matters

Google's current AdMob help says Android apps need to be publicly available in a supported app store to link the app to AdMob. The supported stores listed by Google include Google Play and certain named third-party stores. A standalone APK download is not itself a store listing. Google also says apps listed only in a third-party store are not currently required to verify with `app-ads.txt`; that exception does not establish eligibility for an app distributed only as a direct APK.

Therefore, **do not claim AdMob verification, production ad delivery, or monetization readiness for this direct-APK distribution**. The owner must check the app's exact status in AdMob and confirm with Google whether the intended distribution channel can be linked and reviewed. The Android package ID to use when checking is `app.nova.windowscloud`.

## `app-ads.txt` hosting

If AdMob requires verification for the app, its help describes publishing `app-ads.txt` at the root of a developer website associated with the app's supported store listing, then allowing the crawler to verify it. No developer domain, store listing, or public policy URL has been supplied, so nothing has been published. Do not present the template as live or verified. Once an eligible developer domain is provided, publish the exact authorized seller file at the domain root and check the status in the AdMob account.

## Owner checklist before production ads

1. Confirm the app's distribution/store listing is accepted for this AdMob app; direct APK distribution alone is not assumed eligible.
2. In AdMob, confirm the App ID and both ad units belong to the intended publisher account and the app is approved/ready.
3. Confirm audience/child-directed settings and the countries in which the app will be used; configure AdMob and UMP accordingly.
4. Supply the legal developer name, privacy contact, and a public HTTPS privacy-policy URL. The file `docs/privacy-policy-draft.md` is not a published URL.
5. If prompted by AdMob for `app-ads.txt`, supply a developer domain associated with the supported store listing, host the template line at its root, and wait for the in-account verification result.

## Official references

- [Set up an app in AdMob](https://support.google.com/admob/answer/9989980?hl=en)
- [Verify your app with app-ads.txt](https://support.google.com/admob/answer/14538460?hl=en)
- [Set up an app-ads.txt file](https://support.google.com/admob/answer/9363762?hl=en)
- [Resolve issues with app-ads.txt](https://support.google.com/admob/answer/9776740?hl=en)
