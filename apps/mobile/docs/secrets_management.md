# Secrets Management Guide for Dayliz App

This document provides guidelines for managing sensitive information and API credentials in the Dayliz App project.

## Important: Never Commit Secrets to Git

API keys, client secrets, and other sensitive credentials should **never** be committed to the Git repository. These secrets could be exposed in the Git history even if they are later removed.

## Sensitive Files

The following files contain sensitive information and should not be committed to the repository:

1. `.env` - Contains environment variables including API keys and secrets
2. `client_secret_web.json` - Contains Google OAuth client credentials
3. `/android/app/google-services.json` - Contains Firebase and Google service credentials

These files are now included in the `.gitignore` file to prevent accidental commits.

## How to Set Up Your Development Environment

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Fill in your own credentials in the `.env` file:
   - Supabase URL and anon key
   - Google client IDs and secrets
   - Other API keys

3. Obtain the necessary credential files:
   - `client_secret_web.json` for Google OAuth
   - `google-services.json` for Firebase/Google services

These files should be obtained from a secure source (e.g., team lead, secure file sharing, or by creating your own credentials for development).

## Creating Your Own Development Credentials

### Google OAuth Credentials

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to "APIs & Services" > "Credentials"
4. Create OAuth client IDs for Web and Android
5. Download the credentials as JSON files

### Supabase Credentials

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key from the project settings
3. Add these to your `.env` file

## Sharing Secrets Securely

When you need to share secrets with team members:

1. **Never** share through Git or public channels
2. Use secure methods like:
   - Password managers (LastPass, 1Password, etc.)
   - Encrypted messaging
   - Secure file sharing services

## Handling Secrets in CI/CD

For CI/CD pipelines:

1. Use environment variables in your CI/CD platform
2. Use secrets management services (GitHub Secrets, GitLab CI/CD Variables, etc.)
3. Never print secrets in build logs

## What to Do If Secrets Are Accidentally Committed

If secrets are accidentally committed to the repository:

1. **Immediately** rotate/regenerate all exposed credentials
2. Remove the secrets from the repository
3. Use tools like `git filter-branch` or BFG Repo-Cleaner to remove secrets from Git history
4. Notify all team members to update their credentials

Remember: Once secrets are committed to a public repository, they should be considered compromised even if quickly removed.
