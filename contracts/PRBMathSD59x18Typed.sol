// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

import "./PRBMath.sol";

/// @title PRBMathSD59x18Typed
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
/// @dev This is the same as PRBMathSD59x18, except that it works with structs instead of raw uint256s.
library PRBMathSD59x18Typed {
    /// STORAGE ///

    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 = 57896044618658097711785492504343953926634992332820282019728000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 = -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 = -57896044618658097711785492504343953926634992332820282019728000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        unchecked {
            require(x.value > MIN_SD59x18);
            result = PRBMath.SD59x18({ value: x.value < 0 ? -x.value : x.value });
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Adds two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    /// @param x The first signed 59.18-decimal fixed-point number to add.
    /// @param y The second signed 59.18-decimal fixed-point number to add.
    /// @param result The result as a signed 59.18 decimal fixed-point number.
    function add(PRBMath.SD59x18 memory x, PRBMath.SD59x18 memory y)
        internal
        view
        returns (PRBMath.SD59x18 memory result, uint256 gasUsed)
    {
        uint256 startGas = gasleft();
        result = PRBMath.SD59x18({ value: x.value + y.value });
        gasUsed = startGas - gasleft();
    }

    /// @notice Calculates arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(PRBMath.SD59x18 memory x, PRBMath.SD59x18 memory y)
        internal
        view
        returns (PRBMath.SD59x18 memory result, uint256 gasUsed)
    {
        uint256 startGas = gasleft();
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            int256 rValue = (x.value >> 1) + (y.value >> 1) + (x.value & y.value & 1);
            result = PRBMath.SD59x18({ value: rValue });
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        require(x.value <= MAX_WHOLE_SD59x18);
        unchecked {
            int256 remainder = x.value % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                int256 rValue = x.value - remainder;
                if (x.value > 0) {
                    rValue += SCALE;
                }
                result = PRBMath.SD59x18({ value: rValue });
            }
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be type(int256).min.
    /// - y cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(PRBMath.SD59x18 memory x, PRBMath.SD59x18 memory y)
        internal
        view
        returns (PRBMath.SD59x18 memory result, uint256 gasUsed)
    {
        uint256 startGas = gasleft();
        int256 xValue = x.value;
        int256 yValue = y.value;
        require(xValue > type(int256).min);
        require(yValue > type(int256).min);

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = xValue < 0 ? uint256(-xValue) : uint256(xValue);
            ay = yValue < 0 ? uint256(-yValue) : uint256(yValue);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rUnsigned = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        require(rUnsigned <= uint256(type(int256).max));

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(xValue, sub(0, 1))
            sy := sgt(yValue, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = PRBMath.SD59x18({ value: sx ^ sy == 1 ? -int256(rUnsigned) : int256(rUnsigned) });
        gasUsed = startGas - gasleft();
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (PRBMath.SD59x18 memory result) {
        result = PRBMath.SD59x18({ value: 2718281828459045235 });
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x.value < -41446531673892822322) {
            return (PRBMath.SD59x18({ value: 0 }), startGas - gasleft());
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        require(x.value < 133084258667509499441);

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x.value * LOG2_E;
            PRBMath.SD59x18 memory exponent = PRBMath.SD59x18({ value: (doubleScaleProduct + HALF_SCALE) / SCALE });
            (result, ) = exp2(exponent);
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        // This works because 2^(-x) = 1/2^x.
        if (x.value < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x.value < -59794705707972522261) {
                return (PRBMath.SD59x18({ value: 0 }), startGas - gasleft());
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                PRBMath.SD59x18 memory exponent = PRBMath.SD59x18({ value: -x.value });
                (PRBMath.SD59x18 memory foo, ) = exp2(exponent);
                result = PRBMath.SD59x18({ value: 1e36 / foo.value });
                gasUsed = startGas - gasleft();
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit fixed-point representation.
            require(x.value < 192e18);

            unchecked {
                // Convert x to the 192-64-bit fixed-point format.
                uint256 x192x64 = (uint256(x.value) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = PRBMath.SD59x18({ value: int256(PRBMath.exp2(x192x64)) });
            }
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        require(x.value >= MIN_WHOLE_SD59x18);
        unchecked {
            int256 remainder = x.value % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                int256 rValue = x.value - remainder;
                if (x.value < 0) {
                    rValue -= SCALE;
                }
                result = PRBMath.SD59x18({ value: rValue });
            }
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        unchecked { result = PRBMath.SD59x18({ value: x.value % SCALE }); }
        gasUsed = startGas - gasleft();
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        unchecked {
            require(x >= MIN_SD59x18 / SCALE && x <= MAX_SD59x18 / SCALE);
            result = PRBMath.SD59x18({ value: x * SCALE });
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(PRBMath.SD59x18 memory x, PRBMath.SD59x18 memory y)
        internal
        view
        returns (PRBMath.SD59x18 memory result, uint256 gasUsed)
    {
        uint256 startGas = gasleft();
        if (x.value == 0) {
            return (PRBMath.SD59x18({ value: 0 }), startGas - gasleft());
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x.value * y.value;
            require(xy / x.value == y.value);

            // The product cannot be negative.
            require(xy >= 0);

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.SD59x18({ value: int256(PRBMath.sqrt(uint256(xy))) });
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Calculates 1 / x, rounding towards zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = PRBMath.SD59x18({ value: 1e36 / x.value });
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            (PRBMath.SD59x18 memory log, ) = log2(x);
            int256 rValue = (log.value * SCALE) / LOG2_E;
            result = PRBMath.SD59x18({ value: rValue });
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        int256 xValue = x.value;
        require(xValue > 0);

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this
        // contract.
        int256 rValue;

        // prettier-ignore
        assembly {
            switch xValue
            case 1 { rValue := mul(SCALE, sub(0, 18)) }
            case 10 { rValue := mul(SCALE, sub(1, 18)) }
            case 100 { rValue := mul(SCALE, sub(2, 18)) }
            case 1000 { rValue := mul(SCALE, sub(3, 18)) }
            case 10000 { rValue := mul(SCALE, sub(4, 18)) }
            case 100000 { rValue := mul(SCALE, sub(5, 18)) }
            case 1000000 { rValue := mul(SCALE, sub(6, 18)) }
            case 10000000 { rValue := mul(SCALE, sub(7, 18)) }
            case 100000000 { rValue := mul(SCALE, sub(8, 18)) }
            case 1000000000 { rValue := mul(SCALE, sub(9, 18)) }
            case 10000000000 { rValue := mul(SCALE, sub(10, 18)) }
            case 100000000000 { rValue := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { rValue := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { rValue := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { rValue := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { rValue := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { rValue := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { rValue := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { rValue := 0 }
            case 10000000000000000000 { rValue := SCALE }
            case 100000000000000000000 { rValue := mul(SCALE, 2) }
            case 1000000000000000000000 { rValue := mul(SCALE, 3) }
            case 10000000000000000000000 { rValue := mul(SCALE, 4) }
            case 100000000000000000000000 { rValue := mul(SCALE, 5) }
            case 1000000000000000000000000 { rValue := mul(SCALE, 6) }
            case 10000000000000000000000000 { rValue := mul(SCALE, 7) }
            case 100000000000000000000000000 { rValue := mul(SCALE, 8) }
            case 1000000000000000000000000000 { rValue := mul(SCALE, 9) }
            case 10000000000000000000000000000 { rValue := mul(SCALE, 10) }
            case 100000000000000000000000000000 { rValue := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { rValue := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { rValue := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { rValue := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { rValue := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { rValue := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { rValue := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { rValue := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { rValue := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { rValue := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { rValue := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { rValue := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { rValue := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { rValue := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { rValue := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { rValue := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 58) }
            default {
                rValue := MAX_SD59x18
            }
        }

        if (rValue != MAX_SD59x18) {
            result = PRBMath.SD59x18({ value: rValue });
        } else {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                (PRBMath.SD59x18 memory log, ) = log2(x);
                rValue = (log.value * SCALE) / 3321928094887362347;
                result = PRBMath.SD59x18({ value: rValue });
            }
        }
        gasUsed = startGas - gasleft();
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        int256 xValue = x.value;
        require(xValue > 0);
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (xValue >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    xValue := div(1000000000000000000000000000000000000, xValue)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(xValue / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            int256 rValue = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = xValue >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return (PRBMath.SD59x18({ value: rValue * sign }), startGas - gasleft());
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    rValue += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result = PRBMath.SD59x18({ value: rValue * sign });
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// alawys 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function mul(PRBMath.SD59x18 memory x, PRBMath.SD59x18 memory y)
        internal
        view
        returns (PRBMath.SD59x18 memory result, uint256 gasUsed)
    {
        uint256 startGas = gasleft();
        int256 xValue = x.value;
        int256 yValue = y.value;
        require(xValue > MIN_SD59x18);
        require(yValue > MIN_SD59x18);

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = xValue < 0 ? uint256(-xValue) : uint256(xValue);
            ay = yValue < 0 ? uint256(-yValue) : uint256(yValue);

            uint256 rUnsigned = PRBMath.mulDivFixedPoint(ax, ay);
            require(rUnsigned <= uint256(MAX_SD59x18));

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(xValue, sub(0, 1))
                sy := sgt(yValue, sub(0, 1))
            }
            result = PRBMath.SD59x18({ value: sx ^ sy == 1 ? -int256(rUnsigned) : int256(rUnsigned) });
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (PRBMath.SD59x18 memory result) {
        result = PRBMath.SD59x18({ value: 3141592653589793238 });
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(PRBMath.SD59x18 memory x, PRBMath.SD59x18 memory y)
        internal
        view
        returns (PRBMath.SD59x18 memory result, uint256 gasUsed)
    {
        uint256 startGas = gasleft();
        if (x.value == 0) {
            result = PRBMath.SD59x18({ value: y.value == 0 ? SCALE : int256(0) });
        } else {
            (PRBMath.SD59x18 memory log, ) = log2(x);
            (PRBMath.SD59x18 memory foo, ) = mul(log, y);
            (result, ) = exp2(foo);
        }
        gasUsed = startGas - gasleft();
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(PRBMath.SD59x18 memory x, uint256 y) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        (PRBMath.SD59x18 memory foo, ) = abs(x);
        uint256 xAbs = uint256(foo.value);

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        require(rAbs <= uint256(MAX_SD59x18));

        // Is the base negative and the exponent an odd number?
        bool isNegative = x.value < 0 && y & 1 == 1;
        result = PRBMath.SD59x18({ value: isNegative ? -int256(rAbs) : int256(rAbs) });
        gasUsed = startGas - gasleft();
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (PRBMath.SD59x18 memory result) {
        result = PRBMath.SD59x18({ value: SCALE });
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// Caveats:
    /// - The maximum fixed-point number permitted is 57896044618658097711785492504343953926634.992332820282019729.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(PRBMath.SD59x18 memory x) internal view returns (PRBMath.SD59x18 memory result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        require(x.value >= 0);
        require(x.value < 57896044618658097711785492504343953926634992332820282019729);
        unchecked {
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            int256 rValue = int256(PRBMath.sqrt(uint256(x.value * SCALE)));
            result = PRBMath.SD59x18({ value: rValue });
            gasUsed = startGas - gasleft();
        }
    }

    /// @notice Subtracts one signed 59.18-decimal fixed-point number from another one, returning a new signed 59.18-decimal
    /// fixed-point number.
    /// @param x The signed 59.18-decimal fixed-point number from which to subtract the other one.
    /// @param y The signed 59.18-decimal fixed-point number to subtract from the other one.
    /// @param result The result as a signed 59.18 decimal fixed-point number.
    function sub(PRBMath.SD59x18 memory x, PRBMath.SD59x18 memory y)
        internal
        view
        returns (PRBMath.SD59x18 memory result, uint256 gasUsed)
    {
        uint256 startGas = gasleft();
        result = PRBMath.SD59x18({ value: x.value - y.value });
        gasUsed = startGas - gasleft();
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(PRBMath.SD59x18 memory x) internal view returns (int256 result, uint256 gasUsed) {
        uint256 startGas = gasleft();
        unchecked { result = x.value / SCALE; }
        gasUsed = startGas - gasleft();
    }
}
