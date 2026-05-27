"""Simple calculator — de code die Jenkins zal controleren."""


def add(a: int, b: int) -> int:
    """Optellen van twee getallen."""
    return a + b


def subtract(a: int, b: int) -> int:
    """Aftrekken van twee getallen."""
    return a - b


def multiply(a: int, b: int) -> int:
    """Vermenigvuldigen van twee getallen."""
    return a * b


def divide(a: int, b: int) -> float:
    """Delen van twee getallen."""
    if b == 0:
        raise ValueError("Deling door nul is niet toegestaan")
    return a / b
