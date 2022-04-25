package jp.unaguna.example;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

public class Mod1ATest {
    @Test
    public void testP1() {
        // pass
    }
    @Test
    public void testF1() {
        assert false;
    }
    @Test
    @Disabled
    public void testI1() {
        // do nothing
    }
    @Test
    @Disabled
    public void testI2() {
        // do nothing
    }
}
