# AI setup (Gemini) — food detection & diet planning

Forme can use Google's **Gemini** model for two things:

1. **Food detection** — type *any* food or activity on the Diet page and Gemini
   estimates the calories (not just the built-in list).
2. **Diet planning** — "Plan my diet with AI" builds a one-day meal plan from
   your goals, dietary needs and allergies.

Both features work **without** a key, using an offline estimator and a sample
plan. Add a key to make them real and cover any food.

## 1. Get a Gemini API key

1. Go to <https://aistudio.google.com/app/apikey> and sign in.
2. Create an API key (the free tier is fine to start).
3. Copy the key.

## 2. Build with the key

The key is passed at build time with `--dart-define` so it never gets
hard-coded into the source:

```bash
flutter run    --dart-define=GEMINI_API_KEY=your_key_here
flutter build apk --release --dart-define=GEMINI_API_KEY=your_key_here
```

That's it. When the key is present, `GeminiService.configured` is true and the
Diet page uses Gemini automatically; otherwise it falls back.

## How it works in the code

- `lib/services/gemini_service.dart` calls the Gemini REST API
  (`models/gemini-2.0-flash:generateContent`). It reads the key from
  `String.fromEnvironment('GEMINI_API_KEY')`.
- `estimateCalories(text)` → an integer (negative = calories burned for
  activities). The Diet page tries this first, then the offline
  `FoodEstimator`.
- `planDiet(...)` → a short plain-text plan shown on the Diet Plan screen.

## Notes

- Keep your key private. For a shipped app, restrict the key in Google Cloud and
  consider proxying requests through your own backend rather than shipping the
  key in the APK.
- On web, requests go straight to Google; on Android they work as-is.
- Gemini model names change over time — update `_model` in `gemini_service.dart`
  if needed.
