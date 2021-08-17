"""
Module containig available actions in CUDA compilation process
"""

# Action name for link phase
CUDA_LINK = 'link'

# Action name for compile phase
CUDA_COMPILE = 'compile'

CUDA_ACTION_NAMES = struct(
    link = CUDA_LINK,
    compile = CUDA_COMPILE,
)
