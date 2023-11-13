/// @title IModuleRegistry
/// @notice Module Registry Interface
interface IModuleRegistry {

    event ModuleAdded(address indexed ipOrg, string indexed moduleKey, BaseModule module);

    event ModuleRemoved(address indexed ipOrg, string indexed moduleKey, BaseModule module);

    event ModuleExecuted (
        address indexed ipOrg,
        string indexed moduleKey,
        address indexed caller,
        bytes selfParams,
        bytes[] preHookParams,
        bytes[] postHookParams
    );

    event ModuleConfigured(
        address indexed ipOrg,
        string indexed moduleKey,
        address indexed caller,
        bytes params
    );

    function protocolModules(string moduleKey) external returns (BaseModule);
}
