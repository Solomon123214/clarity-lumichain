[Previous test imports and tests remain unchanged...]

Clarinet.test({
    name: "Schedule validation and management with authorization",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Register device first
        let block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'register-device', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Test invalid schedule (past block)
        block = chain.mineBlock([
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
        
        // Test unauthorized schedule creation
        block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'create-schedule', [
                types.uint(1),
                types.uint(1),
                types.ascii("device"),
                types.ascii("toggle"),
                types.uint(1),
                types.uint(999999)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr(types.uint(100)); // ERR_NOT_AUTHORIZED
        
        // Test invalid action
        block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'create-schedule', [
                types.uint(1),
                types.uint(1),
                types.ascii("device"),
                types.ascii("invalid"),
                types.uint(1),
                types.uint(999999)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectErr(types.uint(107)); // ERR_INVALID_ACTION
        
        // Test valid schedule creation and unauthorized deactivation
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
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(types.uint(100)); // ERR_NOT_AUTHORIZED
        
        // Test authorized deactivation
        block = chain.mineBlock([
            Tx.contractCall('lumi-control', 'deactivate-schedule', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});
