# MPC Live (gen1)

**Unverified.** The Buildroot config is a copy of the Force one with
guessed values. It needs reference data from a real MPC Live before it can
be trusted. See [reference/](reference).

What's guessed:

- Device tree: `rockchip/rk3288-az01-acv5` (from the compatibles in the
  official MPC update image; not confirmed which one is the Live)
- DT compatible written into the update image: `inmusic,acv5`

What's known from the official MPC gen1 3.10 image: one image covers all
gen1 MPCs. It accepts the compatibles `inmusic,acv5 acv8 acva acva2 acvb
acvm acvr acv5s` and update-mode USB ids `09e8:403a 403b 4046 4047 404b
4052 4056 4057`.

## Build

```sh
make mpc-live
```
