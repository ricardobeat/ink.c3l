import sys
from typing import List, Optional

# A simple data class
class TreeNode:
    """Binary tree node."""
    def __init__(self, val: int, left: Optional['TreeNode'] = None, right: Optional['TreeNode'] = None):
        self.val = val
        self.left = left
        self.right = right

def inorder_traversal(root: Optional[TreeNode]) -> List[int]:
    """Return inorder traversal of a binary tree."""
    result: List[int] = []
    if root is None:
        return result
    stack = []
    current = root
    while current or stack:
        while current:
            stack.append(current)
            current = current.left
        current = stack.pop()
        result.append(current.val)
        current = current.right
    return result

# Build a small tree:    1
#                        / \
#                       2   3
#                      / \
#                     4   5
root = TreeNode(1, TreeNode(2, TreeNode(4), TreeNode(5)), TreeNode(3))
print(f"Inorder: {inorder_traversal(root)}")

PI = 3.14159
hex_val = 0xFF
binary = 0b1010
octal = 0o755
