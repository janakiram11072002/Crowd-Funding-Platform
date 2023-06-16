import { useColorMode, Button } from "@chakra-ui/react";
import { MoonIcon, SunIcon } from "@chakra-ui/icons";

function DarkModeSwitch() {
  const { colorMode, toggleColorMode } = useColorMode();
  return (
    <Button onClick={toggleColorMode}>{colorMode === "dark" ? "Light": "Dark"}</Button>
  );
}

export default DarkModeSwitch;
