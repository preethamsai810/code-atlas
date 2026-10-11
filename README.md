# Code Atlas: Supabase-connected static app

This is a plain HTML app. There is no `package.json` and no build command is needed.

## 1. Set the Supabase publishable key

Open `public/config.js` in Notepad. Replace `PASTE_YOUR_PUBLISHABLE_KEY_HERE` with the publishable key from your Supabase project (Project Settings > API Keys). Keep the URL already in the file. Save it.

Use only the publishable key (or a legacy `anon` key). Never use a secret or `service_role` key. The publishable key is public in a browser app; Row Level Security (RLS) protects user data.

## 2. Create the database tables (once)

If you have not already run the SQL setup, open `supabase/migrations/0001_init.sql`, copy its contents, then in the Supabase dashboard open SQL Editor > New query, paste and Run. If you already ran this SQL successfully, skip this step; running it again may report that the tables already exist.

## 3. Publish to Netlify

After saving `public/config.js`, open https://app.netlify.com/drop and upload the `public` folder. Netlify will provide a site address. Do not upload the project root; upload `public`.

## 4. Configure email confirmation links

In Supabase, open Authentication > URL Configuration. Set Site URL to the Netlify address. Add that same address to the allowed redirect URLs if the dashboard asks for it. Save changes.

## 5. Verify

Open the Netlify address, create a user account, confirm the email, and sign in. The app should report that progress is saved to the account. Complete a lesson, then sign in on another browser or device to confirm the progress syncs.
