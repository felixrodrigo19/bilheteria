package io.github.felixrodrigo19.reserva.service;

import org.springframework.boot.SpringApplication;

public class TestReservaServiceApplication {

	public static void main(String[] args) {
		SpringApplication.from(ReservaServiceApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
