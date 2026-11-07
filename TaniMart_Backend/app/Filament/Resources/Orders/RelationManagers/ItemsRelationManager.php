<?php

namespace App\Filament\Resources\Orders\RelationManagers;

use App\Models\Product;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ItemsRelationManager extends RelationManager
{
    protected static string $relationship = 'items';

    protected static ?string $title = 'Daftar Produk yang Dipesan';

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('product_id')
                    ->label('Produk')
                    ->relationship('product', 'nama')
                    ->required()
                    ->searchable()
                    ->preload()
                    ->reactive()
                    ->afterStateUpdated(function ($state, callable $set, callable $get) {
                        if ($state) {
                            $product = Product::find($state);
                            if ($product) {
                                $set('harga_satuan', $product->harga);
                                $qty = (int) ($get('quantity') ?: 1);
                                $set('subtotal', $product->harga * $qty);
                            }
                        }
                    }),
                TextInput::make('quantity')
                    ->label('Jumlah')
                    ->numeric()
                    ->default(1)
                    ->minValue(1)
                    ->required()
                    ->reactive()
                    ->afterStateUpdated(function ($state, callable $set, callable $get) {
                        $harga = (int) ($get('harga_satuan') ?: 0);
                        $qty = (int) ($state ?: 1);
                        $set('subtotal', $harga * $qty);
                    }),
                TextInput::make('harga_satuan')
                    ->label('Harga Satuan')
                    ->numeric()
                    ->prefix('Rp')
                    ->required()
                    ->reactive()
                    ->afterStateUpdated(function ($state, callable $set, callable $get) {
                        $qty = (int) ($get('quantity') ?: 1);
                        $harga = (int) ($state ?: 0);
                        $set('subtotal', $harga * $qty);
                    }),
                TextInput::make('subtotal')
                    ->label('Subtotal')
                    ->numeric()
                    ->prefix('Rp')
                    ->required(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('id')
            ->columns([
                TextColumn::make('product.nama')
                    ->label('Nama Produk')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('product.kategori')
                    ->label('Kategori')
                    ->sortable(),
                TextColumn::make('quantity')
                    ->label('Jumlah Beli')
                    ->sortable(),
                TextColumn::make('product.satuan_jual')
                    ->label('Satuan'),
                TextColumn::make('harga_satuan')
                    ->label('Harga Satuan')
                    ->money('IDR', locale: 'id')
                    ->sortable(),
                TextColumn::make('subtotal')
                    ->label('Subtotal')
                    ->money('IDR', locale: 'id')
                    ->sortable(),
            ])
            ->filters([
                //
            ])
            ->headerActions([
                CreateAction::make(),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
