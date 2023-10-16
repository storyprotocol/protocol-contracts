
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ProxyHelper {

    function _deployUUPSProxy(address _logic, bytes memory _data) internal returns (address) {
        ERC1967Proxy proxy = new ERC1967Proxy(_logic, _data);
        return address(proxy);
    }
}
