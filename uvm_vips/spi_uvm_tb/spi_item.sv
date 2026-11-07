class spi_item extends uvm_sequence_item;

  bit adc_spi_sck;
  bit adc_spi_mosi;
  rand bit adc_spi_miso;
  bit adc_spi_cs_n;

  `uvm_object_utils(spi_item)

  function new(string name="spi_item"); super.new(name); endfunction
endclass
