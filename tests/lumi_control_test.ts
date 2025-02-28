[Previous test imports and first three tests remain unchanged...]

Clarinet.test({
    name: "Can manage device groups with proper authorization",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create group
        let block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'create-group', [
                types.uint(1),
                types.ascii("Living Room")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Register device
        block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'register-device', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        // Test unauthorized group addition
        block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'add-to-group', [
                types.uint(1),
                types.uint(1)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr(types.uint(100)); // ERR_NOT_AUTHORIZED
        
        // Test successful group addition and removal
        block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'add-to-group', [
                types.uint(1),
                types.uint(1)
            ], deployer.address),
            Tx.contractCall('lumi-control', 'remove-from-group', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
    }
});

Clarinet.test({
    name: "Schedule validation and management",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Test invalid schedule (past block)
        let block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'create-schedule', [
                types.uint(1),
                types.uint(1),
                types.ascii("device"),
                types.ascii("toggle"),
                types.uint(1),
                types.uint(1) // Past block
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectErr(types.uint(106)); // ERR_INVALID_BLOCK
        
        // Test valid schedule creation and deactivation
        block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'create-schedule', [
                types.uint(1),
                types.uint(1),
                types.ascii("device"),
                types.ascii("toggle"),
                types.uint(1),
                types.uint(999999)
            ], deployer.address),
            Tx.contractCall('lumi-control', 'deactivate-schedule', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
    }
});
