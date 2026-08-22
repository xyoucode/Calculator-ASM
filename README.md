# ε Calculator (8086 Assembly)

A command-line calculator written in **x86 (8086) Assembly** for MS-DOS, supporting four number systems and a full set of arithmetic and bitwise operations. Built as an Architecture des Ordinateurs (Computer Architecture) course project.

> "An assembly language calculator supporting basic arithmetic operations" — and a bit more than that.

---

##  Features

| Category | Details |
|---|---|
| **Number systems** | Decimal, Binary, Octal, Hexadecimal |
| **Arithmetic** | Addition, Subtraction, Multiplication, Division (quotient + remainder), Power |
| **Bitwise** | AND, OR, XOR, NOT, Shift Left, Shift Right |
| **Signed numbers** | Full support for negative values in decimal mode |
| **Error handling** | Overflow detection, division-by-zero protection, input validation, invalid exponent/shift-range checks |
| **UX** | Repeat calculations without restarting the program |

---

## 📸 How it works

The program runs entirely through DOS interrupts (`INT 21h`) in a simple text menu:

1. Choose a number system (decimal / binary / octal / hex)
2. Enter the first number `A`
3. Choose an operation
4. Enter the second number `B` (skipped for the unary `NOT` operation)
5. View the result — instantly reused for another calculation if desired

```
Select number system:
----------------------
  1. Decimal        3. Octal
  2. Binary         4. Hexadecimal
Choice: 1

Enter first  number  A = 25
Select operation:
------------------
  Arithmetic:                 Bitwise:
   +  Addition                 &  AND
   -  Subtraction               |  OR
   *  Multiplication            x  XOR
   /  Division (quo. + rem.)    !  NOT      (unary)
   ^  Power (A raised to B)     l  Shift Left
                                 r  Shift Right
Choice: +
Enter second number  B = 17

  Result: 25 + 17 = 42
```

---

## 🗂️ Project Structure

```
Calculator-ASM/
└── ARCHI22.PROJECT.asm     # Full source code (single-file program)
```

The source is organized into clearly separated, documented procedures:

| Procedure | Responsibility |
|---|---|
| `main` | Program flow: menus, input/output orchestration, dispatch to operations |
| `read_number` | Reads user input digit-by-digit and converts it to a value, validating each digit against the active number system |
| `display_number` | Converts a value back into text in the active number system and prints it |
| `show_binary_result` / `show_division_result` / `show_not_result` | Format and print results for binary, division, and unary operations respectively |

---

## ⚙️ Building & Running

You'll need a DOS-compatible assembler/linker and an x86 emulator (real MS-DOS is optional — [DOSBox](https://www.dosbox.com/) works great).

**With TASM:**
```bash
TASM ARCHI22.PROJECT.asm
TLINK ARCHI22.PROJECT.obj
ARCHI22.PROJECT.exe
```

**With MASM:**
```bash
MASM ARCHI22.PROJECT.asm;
LINK ARCHI22.PROJECT.obj;
ARCHI22.PROJECT.exe
```

Run the resulting `.exe` inside DOSBox or any DOS environment.

---

## 🧠 What this project demonstrates

This project was built to practice core low-level programming concepts:

- **Number representation**: manual base conversion (binary/octal/decimal/hex) without library support
- **Two's complement arithmetic**: signed number handling, negation, and overflow detection using the `OF` flag
- **DOS system calls**: character I/O via `INT 21h`
- **Structured assembly design**: reusable procedures, macros, and register-preserving calling conventions (`push`/`pop`)
- **Defensive programming**: input validation, division-by-zero guards, and range checks — even at the instruction level

---

## 🛠️ Possible improvements

- [ ] Support numbers larger than 16 bits (32-bit operands via `DX:AX`)
- [ ] Direct conversion mode: enter a number once, display it in all four bases
- [ ] Colored terminal output via `INT 10h`
- [ ] Fixed-point / decimal fraction support

---

## 📄 License

This project is available for educational use. Feel free to fork it, study it, or build on it.

---

**Author:** youcef 

