package be.poc.app;

/**
 * Eenvoudige calculator klasse voor de POC.
 */
public class Calculator {

    /**
     * Telt twee getallen op.
     *
     * @param a eerste getal
     * @param b tweede getal
     * @return de som van a en b
     */
    public int add(final int a, final int b) {
        return a + b;
    }

    /**
     * Trekt twee getallen af.
     *
     * @param a eerste getal
     * @param b tweede getal
     * @return het verschil van a en b
     */
    public int subtract(final int a, final int b) {
        return a - b;
    }

    /**
     * Vermenigvuldigt twee getallen.
     *
     * @param a eerste getal
     * @param b tweede getal
     * @return het product van a en b
     */
    public int multiply(final int a, final int b) {
        return a * b;
    }

    /**
     * Deelt twee getallen.
     *
     * @param a teller
     * @param b noemer
     * @return het quotiënt
     * @throws IllegalArgumentException als b nul is
     */
    public double divide(final int a, final int b) {
        if (b == 0) {
            throw new IllegalArgumentException("Deler mag niet nul zijn");
        }
        return (double) a / b;
    }
}
