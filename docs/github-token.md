# Create a GitHub Token

`git-setup` uses a GitHub Personal Access Token during **Run full setup**. The
token connects GitHub CLI with your account and lets the assistant add the SSH,
SSH-signing, and GPG public keys it creates.

Create the token once, save it in a password manager such as 1Password or
Bitwarden, and reuse it whenever you configure a new machine.

## Required Scopes

Create a **Personal Access Token (classic)** with these scopes:

- `repo` — GitHub CLI authentication and the optional integration-test push.
- `read:org` — GitHub CLI account access.
- `gist` — GitHub CLI account access.
- `write:public_key` — Upload authentication and SSH-signing public keys.
- `write:gpg_key` — Upload the public GPG key.

## Create the Token on GitHub

1. Sign in to [GitHub](https://github.com).
2. Open **Settings** from your profile menu.
3. Select **Developer settings** in the left sidebar.
4. Select **Personal access tokens**, then **Tokens (classic)**.
5. Select **Generate new token (classic)**.
6. Give it a recognizable name, such as `git-setup`.
7. Choose an expiration that suits how you manage your credentials.
8. Select the [required scopes](#required-scopes).
9. Select **Generate token** and save the value in your password manager.

GitHub shows the token only once. When `git-setup` asks for it, paste it at the
prompt; the value is not echoed to the terminal.
