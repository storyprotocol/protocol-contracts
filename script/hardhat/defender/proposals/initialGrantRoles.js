const roles = require('../../utils/roles.json');
const deployment = require('../../../../deployment-11155111.json');
const safeAddress = process.env.SEPOLIA_MULTISIG_ADDRESS;

module.exports = {
    title: 'Grant Role for deployment contract',
    description: 'Grants the roles needed for a StoryProtocol deployment, and admin access to the multisig',
    network: 'sepolia',
    steps: [
        {
            contractName: 'AccessControlSingleton',
            functionName: 'grantRole',
            functionInputs: [roles["RELATIONSHIP_MANAGER_ROLE"], safeAddress],
        },
        {
            contractName: 'AccessControlSingleton',
            functionName: 'grantRole',
            functionInputs: [roles["LICENSING_MANAGER_ROLE"], safeAddress],
        },
        {
            contractName: 'AccessControlSingleton',
            functionName: 'grantRole',
            functionInputs: [roles["IPORG_CREATOR_ROLE"], safeAddress],
        },
        {
            contractName: 'AccessControlSingleton',
            functionName: 'grantRole',
            functionInputs: [roles["MODULE_REGISTRAR_ROLE"], safeAddress],
        }
        // TODO: add contract roles
    ]
}
