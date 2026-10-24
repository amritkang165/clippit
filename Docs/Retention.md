<!-- Purpose: Clarify pin protection, pruning, and deliberate deletion. -->
# Retention and pins

The default history limit is 500 entries. Pins count toward this limit but are
protected from automatic pruning. Older unpinned clips are removed first.

For example, with a limit of 500 and 20 pins, there is room for 480 unpinned
clips. If there are 510 pins, all 510 remain and no unpinned entries can be kept.
Lowering the limit can therefore delete unpinned history immediately when the
new setting is applied. Raising it later does not recover deleted entries.

Pins do not protect against deliberate deletion: Delete can remove a selected
pinned entry, and confirmed Clear all includes pins. Owned image files are
cleaned up along with removed entries. The footer counts retained entries from
the current local day, not a permanent total of all copy operations.
