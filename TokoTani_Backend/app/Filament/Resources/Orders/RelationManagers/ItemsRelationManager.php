<?php

namespace App\Filament\Resources\Orders\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ItemsRelationManager extends RelationManager
{
    protected static string $relationship = 'items';

    protected static ?string $title = 'Daftar Produk yang Dipesan';

    public function isReadOnly(): bool
    {
        return true;
    }

    public function form(Schema $schema): Schema
    {
        return $schema->components([]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('id')
            ->columns([
                ImageColumn::make('product.gambar')
                    ->label('Foto')
                    ->disk('public')
                    ->square()
                    ->size(48),
                TextColumn::make('product.nama')
                    ->label('Nama Produk')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->wrap(),
                TextColumn::make('product.kategori')
                    ->label('Kategori')
                    ->sortable(),
                TextColumn::make('quantity')
                    ->label('Jumlah Beli')
                    ->sortable(),
                TextColumn::make('product.satuan_jual')
                    ->label('Satuan')
                    ->default('item'),
                TextColumn::make('harga_satuan')
                    ->label('Harga Checkout')
                    ->money('IDR', locale: 'id')
                    ->sortable(),
                TextColumn::make('subtotal')
                    ->label('Subtotal')
                    ->money('IDR', locale: 'id')
                    ->sortable()
                    ->weight('bold'),
            ])
            ->headerActions([])
            ->recordActions([])
            ->toolbarActions([]);
    }
}
