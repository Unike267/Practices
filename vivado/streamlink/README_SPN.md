# Conexión del *acceler* con NEORV32 vía Stream Link (AXI4-Stream)

### Contexto:

Una vez diseñado y testeado el componente *acceler* es hora de conectarlo a la CPU [NEORV32](https://github.com/stnolting/neorv32). Existen varios modos de añadir un módulo a dicho procesador:

- External Bus Interface.
- Custom Fuction Subsystem.
- Custom Fuction Unit.
- Stream Link Interface.

En este caso se escoge la conexión vía Stream Link.

### Procedimiento:

El diagrama que se desea implementar es el siguiente:

![Plano](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/PLANO_SLINK.png)

Para ello se sigue el siguiente procedimiento:

- Se realiza un capa superior llamada *acceler_axi_buffer* en la cual se generan las señales AXI4-Stream necesarias. Además se realiza la lógica necesaria para las señales internas de lectura y escritura del *acceler*.
- Se mapea las señales de la capa *acceler-axi-buffer* con las señales del Stream Link. Para ello en el top del diseño a implementar *neorv32_test_top* se añade como componente el *acceler_axi_buffer* y se enruta las señales con el *neorv32_top*.
    - Nota: ya que el neorv32 utiliza **señales ulogic**, será necesario transformarlas. Para el caso de las señales *std_logic_vector* se aplica directamente la función *to_std_ulogic_vector()*. Pero para el caso de las señales *std_logic* será necesario transformarlas a *bit* con la función *to_bit()* y luego a *std_ulogic* con la función *to_std_ulogic()*.
    - Nota 2: al importar el *neorv32_top* en el *generic map* se ha de añadir las constantes propias del modulo SLINK para activar la sintetización del módulo y decidir la profundidad de las fifos *RX* y *TX*. Así como en el *port map* se ha de añadir las señales propias de la interface.
- Se realiza un programa *.c* para escribir/leer datos por la interface SLINK y mostrarlos por UART.
    - Nota: ~~al utilizar las funciones propias del SLINK estas recurren a la librería [neorv32_slink.c](https://github.com/stnolting/neorv32/blob/main/sw/lib/source/neorv32_slink.c). **En dicha librería hay un bug**, en concreto en la línea 51 donde se escribe *if (NEORV32_SYSINFO->SOC & (1 << SYSINFO_SOC_IO_SDI))* cuando debería poner *if (NEORV32_SYSINFO->SOC & (1 << SYSINFO_SOC_IO_SLINK))*.~~ **El bug es resuelto en la [pull](https://github.com/stnolting/neorv32/pull/717).**
- Tras arreglar el bug, se compila el programa y se sobrescribe la *neorv32_application_image*. Lo cual hará que al sintetizar el diseño se cargue nuestro programa en la memoria de instrucciones *neorv32_imem.default*, véase [#6](https://gitlab.com/EHU-GDED/NEORV32/-/issues/6).
- Se sintetiza el diseño completo mediante el archivo *create_project.tcl*. Tras ello, se establece comunicación vía UART y se muestran los resultados.

### Resultados:

Se obtiene los siguientes resultados empleando la terminal CuteCom:

![Resul](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/CUTECOM.png)
