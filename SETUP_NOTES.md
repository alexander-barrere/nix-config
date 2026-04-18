# Setup Notes for Alexander

Repository customized from Anthony's config. Key changes made:

## What's Been Updated
- ✅ GitHub username: `acannizzaro` → `alexander-barrere`  
- ✅ Git name: `acannizzaro` → `Alexander Barrere`
- ✅ Git email: Changed to GitHub noreply format
- ✅ System user: `ajc3` → `dn5v` 
- ✅ Computer names: Updated for Alexander
- ✅ Repository URLs: Point to `alexander-barrere/nix-config`
- ✅ Secrets: Disabled (removed .age files, commented imports)
- ✅ SSH signing: Disabled until you add your key

## Next Steps

1. **Push to your GitHub repo**:
   ```bash
   # Create new repo at github.com/alexander-barrere/nix-config  
   git remote set-url origin git@github.com:alexander-barrere/nix-config.git
   git push -u origin main
   ```

2. **Test the build** (optional):
   ```bash
   # If you have nix installed
   nix build .#darwinConfigurations.personal-mbp.system
   ```

3. **Set up secrets later** (when needed):
   - Generate age recovery key in 1Password
   - Add your SSH public key to `secrets/secrets.nix`
   - Uncomment secret imports in `hosts/common.nix`
   - Re-encrypt secrets with `agenix`

4. **Add SSH signing** (when ready):
   - Uncomment signing config in `home/git.nix`
   - Add your SSH key to the config
   - Update `allowed_signers` file

## Apps That Will Be Installed

**Shared (all machines):**
- Ghostty, 1Password, Hammerspoon, Claude
- Maccy, Obsidian, Raycast, Arc, CleanMyMac, Bartender
- Warp, Cursor, Figma

**Personal machine only:**
- Spotify, VLC, Discord, Notion, Todoist, Magnet

## Working Without Secrets
The config should build and work without secrets. You'll need to:
- Run `gh auth login` manually for GitHub CLI
- Set up any other authentication manually

## Bootstrap Usage
```bash
curl -fsSL https://raw.githubusercontent.com/alexander-barrere/nix-config/main/bootstrap.sh -o /tmp/bootstrap.sh
chmod +x /tmp/bootstrap.sh
/tmp/bootstrap.sh
```