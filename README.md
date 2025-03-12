# Guía de Demostración de MongoDB Replication

## Introducción a MongoDB Replication

La replicación en MongoDB es un mecanismo que permite mantener múltiples copias de los datos en diferentes servidores. Este proceso es sirve para garantizar la alta disponibilidad, tolerancia a fallos y escalabilidad de  aplicaciones que utilizan MongoDB como base de datos.

### ¿Qué es la replicación en MongoDB?

La replicación en MongoDB consiste en crear y mantener múltiples copias de los mismos datos en diferentes servidores. Estas copias se organizan en lo que se conoce como un "replica set", que es un grupo de instancias de MongoDB que mantienen el mismo conjunto de datos.

### Estructura de un Replica Set

Un replica set típico consta de:

1. **Un nodo primario (Primary)**: Este nodo recibe todas las operaciones de escritura. Es el único nodo que puede aceptar operaciones de escritura directamente de los clientes.
2. **Múltiples nodos secundarios (Secondary)**: Estos nodos mantienen copias de los datos del nodo primario. Los secundarios replican los datos del primario aplicando las mismas operaciones que se realizaron en el primario.
3. **Opcionalmente, un árbitro (Arbiter)**: Este es un nodo especial que no contiene datos, pero participa en las elecciones para determinar qué nodo secundario debe convertirse en primario si el primario actual falla.

![alt text](/resources/image.png)

### ¿Cómo funciona la replicación?

El proceso de replicación en MongoDB funciona de la siguiente manera:

1. **Operaciones de escritura**: Todas las operaciones de escritura (inserciones, actualizaciones, eliminaciones) se dirigen al nodo primario.
2. **Registro de operaciones (Oplog)**: El nodo primario registra todas las operaciones que modifican los datos en un registro especial llamado "oplog" (operation log).
3. **Sincronización**: Los nodos secundarios copian continuamente las operaciones desde el oplog del primario y las aplican a sus propios datos, manteniendo así una copia actualizada.
4. **Confirmación asíncrona**: Por defecto, las operaciones de escritura se confirman al cliente una vez que el nodo primario ha completado la operación, sin esperar a que los secundarios la repliquen (aunque esto se puede configurar).

### Elección de un nuevo primario

Si el nodo primario deja de estar disponible (por un fallo de hardware, problemas de red, etc.), los nodos secundarios inician automáticamente un proceso de elección para determinar cuál de ellos se convertirá en el nuevo primario. Este proceso se basa en:

- Cuál nodo tiene los datos más recientes
- La prioridad asignada a cada nodo (configurada por el administrador)
- El número de votos que cada nodo recibe de los demás

La elección requiere una mayoría de votos (conocida como "quórum"). En un replica set de 3 nodos, se necesitan al menos 2 nodos disponibles para elegir un primario. Esta regla de mayoría garantiza la consistencia de los datos y evita situaciones de "cerebro dividido" (split-brain) donde podría haber múltiples primarios.

### Beneficios de la replicación en MongoDB

La replicación proporciona varios beneficios importantes:

1. **Alta disponibilidad**: Si un servidor falla, los datos siguen estando disponibles a través de los otros servidores del replica set.
2. **Tolerancia a fallos**: La replicación protege contra la pérdida de datos en caso de fallos de hardware o interrupciones del servicio.
3. **Distribución de lecturas**: Las operaciones de lectura pueden distribuirse entre los nodos secundarios, lo que permite escalar horizontalmente la capacidad de lectura.
4. **Copias de seguridad sin interrupciones**: Puedes realizar copias de seguridad desde un nodo secundario sin afectar al rendimiento del nodo primario.

## Guía paso a paso de la demostración

> Nota importante: Para una mejor visualización durante la demostración, se recomienda tener abiertas múltiples terminales (al menos 3 o 4), una para cada instancia de MongoDB y otra para los comandos de Docker. Esto facilitará el seguimiento de los cambios en tiempo real.
> 

### Preparación previa

Los pasos 1, 2 y 3 ya están automatizados mediante el script y el docker-compose.yml proporcionados.

### Paso 1: Dar permisos al script y ejecutarlo

```bash
chmod +x setup-mongodb-replication.sh
```
```
sudo ./setup-mongodb-replication.sh
```
Este comando da permisos de ejecución al script y luego lo ejecuta con privilegios de administrador para asegurar que se puedan asignar correctamente los permisos a los directorios de datos.
```
docker-compose up -d
```

### Paso 2: Verificar que los contenedores están en ejecución

```bash
docker ps
```

Este comando muestra todos los contenedores que están corriendo. Deberías ver tres contenedores: mongo1, mongo2 y mongo3.

### Paso 3: Configurar el replica set

```bash
docker exec -it mongo1 mongosh
```

Este comando te conecta a la shell de MongoDB en el primer contenedor. El flag `-it` permite interactuar con la terminal.

Una vez dentro del shell de MongoDB, ejecuta:

```jsx
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:27017", priority: 10 },  // Alta prioridad (primario preferido)
    { _id: 1, host: "mongo2:27017", priority: 5 },   // Prioridad media
    { _id: 2, host: "mongo3:27017", priority: 1 }    // Prioridad baja
  ]
})

```

Este comando inicializa el replica set "rs0" con tres miembros, cada uno con una prioridad diferente. La prioridad determina qué nodo es más probable que se convierta en primario durante una elección, donde un valor más alto significa mayor prioridad.

> Nota: Es recomendable esperar unos 10-15 segundos después de ejecutar este comando para dar tiempo a que MongoDB configure correctamente el replica set y elija un primario.
> 

### Paso 4: Verificar el estado del replica set

```jsx
rs.status()
```

Este comando muestra el estado actual del replica set, incluyendo qué nodo es el primario y cuáles son secundarios. Deberías ver que mongo1 es el primario (debido a su prioridad más alta).

### Paso 5: Insertar datos de prueba en el nodo primario

Deberías estar ya conectado al nodo primario. La terminal debería mostrar algo como `rs0:PRIMARY>` indicando que estás en el nodo primario.

Primero, crea una nueva base de datos:

```jsx
use ejemploReplicacion
```

Luego, inserta algunos datos:

```jsx
db.clientes.insertMany([
  { nombre: "Juan", edad: 30, ciudad: "Madrid" },
  { nombre: "Ana", edad: 25, ciudad: "Barcelona" },
  { nombre: "Luis", edad: 40, ciudad: "Valencia" }
])
```

Finalmente, verifica los datos insertados:

```jsx
db.clientes.find()
```

### Paso 6: Verificar la replicación en un nodo secundario

Abre una nueva terminal y conéctate al segundo nodo:

```bash
docker exec -it mongo2 mongosh
```

Una vez dentro, configura la preferencia de lectura para permitir lecturas en el secundario:

```jsx
db.getMongo().setReadPref("secondary")
```

Selecciona la base de datos:

```jsx
use ejemploReplicacion
```

Verifica que los datos se han replicado:

```jsx
db.clientes.find()
```

Deberías ver los mismos datos que insertaste en el primario. Esto confirma que la replicación está funcionando correctamente.

### Paso 7: Simular fallo del nodo primario

Abre una nueva terminal y ejecuta:

```bash
docker stop mongo1
```

Este comando detiene el contenedor mongo1, simulando un fallo del nodo primario.

> Nota: Es recomendable esperar unos 10-15 segundos después de este comando para dar tiempo a que MongoDB realice el proceso de elección de un nuevo primario.
> 

### Paso 8: Verificar la nueva configuración después del fallo

En una terminal nueva, conéctate a mongo2:

```bash
docker exec -it mongo2 mongosh
```

Verifica el estado del replica set:

```jsx
rs.status()
```

Deberías observar que mongo2 ha sido elegido como el nuevo primario debido a que tiene la segunda prioridad más alta. Esto demuestra la capacidad de MongoDB para mantener la disponibilidad incluso cuando el nodo primario falla.

### Paso 9: Insertar más datos en el nuevo primario

Estando conectado a mongo2 (que ahora es el primario), selecciona la base de datos:

```jsx
use ejemploReplicacion
```

Inserta un nuevo documento:

```jsx
db.clientes.insertOne({ nombre: "Carlos", edad: 55, ciudad: "Sevilla" })
```

Verifica todos los datos:

```jsx
db.clientes.find()
```

Ahora deberías ver los tres documentos originales más el nuevo que acabas de insertar.

### Paso 10: Restaurar el nodo primario original

En una terminal nueva, ejecuta:

```bash
docker start mongo1
```

Este comando reinicia el contenedor mongo1 que habíamos detenido.

> Nota: Es recomendable esperar unos 10-15 segundos para que el nodo se sincronice completamente con el resto del replica set.
> 

### Paso 11: Verificar que el nodo restaurado ha recuperado los datos

Conéctate a mongo1:

```bash
docker exec -it mongo1 mongosh
```

Verifica el estado del replica set:

```jsx
rs.status()
```

Notarás que mongo1, a pesar de tener la prioridad más alta, no se convierte automáticamente en primario al regresar. Esto es por diseño, para evitar cambios constantes en la topología cuando un nodo entra y sale frecuentemente.

Selecciona la base de datos:

```jsx
use ejemploReplicacion
```

Verifica los datos:

```jsx
db.clientes.find()
```

Deberías ver todos los documentos, incluyendo el que se insertó mientras mongo1 estaba caído. Esto demuestra la capacidad de MongoDB para sincronizar automáticamente los datos cuando un nodo se reincorpora al replica set.

> Nota: Es recomendable esperar unos 10-15 segundos para que se complete el proceso de elección.
> 

Verifica el resultado desde cualquier nodo:

```jsx
rs.status()

```

Deberías ver que mongo1 ha vuelto a ser el primario.

### Paso 12: Simular fallo tanto del primario como del secundario con mayor prioridad

Desde una terminal nueva, ejecuta:

```bash
docker stop mongo1
```
```
docker stop mongo2
```

Estos comandos detienen los contenedores mongo1 y mongo2, simulando un fallo tanto del primario como del secundario con mayor prioridad.

### Paso 14: Verificar que el sistema no puede elegir un nuevo primario

Conéctate a mongo3 (el único nodo que queda en funcionamiento):

```bash
docker exec -it mongo3 mongosh
```

Verifica el estado del replica set:

```jsx
rs.status()
```

Observarás que mongo3 no puede convertirse en primario a pesar de ser el único nodo disponible. Esto se debe al requisito de "quórum" en MongoDB, que establece que debe haber una mayoría de nodos (al menos 2 de 3 en este caso) disponibles para elegir un primario. Esta regla es crucial para la seguridad de los datos, ya que evita situaciones de "cerebro dividido" (split-brain) donde podría haber múltiples primarios si la red se segmenta.

### Paso 15: Intentar insertar datos en mongo3

Estando conectado a mongo3, intenta insertar un nuevo documento:

```jsx
use ejemploReplicacion
```
```jsx
db.clientes.insertOne({ nombre: "Elena", edad: 29, ciudad: "Zaragoza" })
```

Recibirás un error indicando que no puedes escribir porque el nodo no es primario y no hay un primario disponible. Esto demuestra cómo MongoDB prioriza la consistencia de los datos sobre la disponibilidad cuando no se puede garantizar un quórum.

### Paso 16: Restaurar todos los nodos

Desde una terminal nueva, ejecuta:

```bash
docker start mongo1
```
```bash
docker start mongo2
```

Estos comandos reinician los contenedores que habíamos detenido.

> Nota: Es recomendable esperar unos 10-15 segundos para que se complete el proceso de elección del nuevo primario y la sincronización de datos.
> 

### Paso 17: Verificar el estado final

Conéctate a cualquier nodo, por ejemplo, mongo1:

```bash
docker exec -it mongo1 mongosh
```

Verifica el estado del replica set:

```jsx
rs.status()
```

Deberías ver que el replica set ha vuelto a su estado normal, con mongo1 como primario debido a su prioridad más alta.

### Paso 18: Limpiar después de la demostración (cuando hayas terminado)

Una vez completada la demostración, puedes limpiar todos los recursos:

```bash
docker stop mongo1 mongo2 mongo3
docker rm mongo1 mongo2 mongo3
docker network rm mongo-repl-network
rm -rf ./data
```

Estos comandos detienen y eliminan los contenedores, eliminan la red creada y borran los directorios de datos.

## Conclusiones

A través de esta demostración, hemos mostrado los aspectos clave de MongoDB Replication:

1. **Configuración de un replica set** con nodos de diferentes prioridades
2. **Replicación de datos** entre nodos, asegurando que todos tengan la misma información
3. **Tolerancia a fallos** cuando el primario falla, con elección automática de un nuevo primario
4. **Elección automática** basada en prioridades, permitiendo controlar qué nodos preferimos como primarios
5. **Sincronización automática** cuando se restaura un nodo, recuperando todos los datos que se modificaron durante su ausencia
6. **Requisito de quórum** para garantizar la consistencia y evitar problemas de "cerebro dividido"

La replicación en MongoDB proporciona alta disponibilidad y tolerancia a fallos, lo que la hace adecuada para entornos de producción donde el tiempo de actividad y la integridad de los datos son críticos.

### AXEL JAVIER AYALA SILES