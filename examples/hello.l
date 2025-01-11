main :: () {
    condition := true;

    if condition {
        print("Hello World !\n");
    } else {
        print("System.out.println(\"Hello World !\");\n");
    }

    value := 100;
    value_ptr := &value;

    expression := 10 / 5 + 10 * 6;
    expression += value_ptr.*;
}
