## Comparing Nix Merging Mechanisms

When combining a base configuration (`commonConfig`) with per-job overrides (`job.localConfig`),
choosing the right merging mechanism prevents accidental overwrites or duplicated code.

| Mechanism                         | Nested Attribute Sets                                              | Lists (`[ ... ]`)                          | Primitives (`str`, `bool`, `int`)                         | Best Use Case                                                                                                  |
| :-------------------------------- | :----------------------------------------------------------------- | :----------------------------------------- | :-------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------- |
| **`//` (Update Operator)**        | **Overwrites** the entire nested set (shallow merge).              | **Overwrites** the entire list.            | **Overwrites** (RHS wins).                                | Flat attribute sets or explicit top-level key replacement.                                                     |
| **`lib.recursiveUpdate`**         | **Deep-merges** keys recursively.                                  | **Overwrites** the entire list (RHS wins). | **Overwrites** (RHS wins).                                | Pure Nix data structures where nested sets should merge, but lists should replace.                             |
| **`lib.recursiveUpdateUntil`**    | **Deep-merges** until a predicate returns `true`, then overwrites. | **Overwrites** the entire list.            | **Overwrites** (RHS wins).                                | Stopping recursion early so specific subtrees are replaced whole rather than merged.                           |
| **`lib.mkMerge` (Module System)** | **Deep-merges** according to NixOS option types.                   | **Concatenates** lists together (`++`).    | Conflicts unless `lib.mkDefault` / `lib.mkForce` is used. | **NixOS module options** (`services.*`), where lists should append and defaults can be selectively overridden. |

### Key Gotchas & Rules of Thumb

1. **Operator Precedence of `//`:**
   `//` binds tighter than function application. Always wrap function calls in parentheses before using `//`:

   ```nix
   # Parsed as: recursiveUpdate a (b // c)
   recursiveUpdate a b // c

   # Correct:
   (recursiveUpdate a b) // c
   ```

2. **NixOS Option Priorities with `lib.mkMerge`:**

   - **`lib.mkDefault` (priority `1000`):** Use on base values you want a job to **replace completely** when overridden (e.g., `timerConfig = lib.mkDefault null;` or `pruneOpts = lib.mkDefault [ ... ];`). A standard definition in `job.localConfig` (priority `100`) replaces it without needing `lib.mkForce`.
   - **Unwrapped lists (priority `100`):** Leave lists like `extraBackupArgs = [ "--tag ${hostname}" ];` unwrapped in `commonConfig` if you want `job.localConfig.extraBackupArgs` to **append** to them.
   - **Attribute sets inside `mkMerge`:** Wrap individual default keys with `lib.mapAttrs (_: lib.mkDefault) { ... }` so per-job overrides (e.g., `rcloneOptions = { checkers = "10"; };`) override matching keys while inheriting the rest.
   - **`lib.mkForce` (priority `50`):** Only needed to completely replace an option that was _not_ wrapped in `lib.mkDefault`.
