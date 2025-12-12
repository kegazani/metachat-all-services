package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

func main() {
	dsn := "postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable"
	
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatalf("Failed to connect to PostgreSQL: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping PostgreSQL: %v", err)
	}

	var exists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname = 'metachat')").Scan(&exists)
	if err != nil {
		log.Fatalf("Failed to check if database exists: %v", err)
	}

	if exists {
		fmt.Println("Database 'metachat' already exists")
		return
	}

	_, err = db.Exec("CREATE DATABASE metachat")
	if err != nil {
		log.Fatalf("Failed to create database: %v", err)
	}

	fmt.Println("Database 'metachat' created successfully!")
}

